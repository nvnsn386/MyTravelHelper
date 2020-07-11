//
//  SearchTrainInteractor.swift
//  MyTravelHelper
//
//  Created by Satish on 11/03/19.
//  Copyright © 2019 Sample. All rights reserved.
//

import Foundation
import XMLParsing

protocol ServiceManagable {
    func fetchAllStations(completionHandler: @escaping (Data?) -> Void)
    func fetchTrainsFromSource(sourceCode: String, completionHandler: @escaping (Data?) -> Void)
    func fetchTrainMovement(trainCode: String, trainDate: String, completionHandler: @escaping (Data?) -> Void)
}

class ServiceManager: ServiceManagable {
    private let baseURL = "http://api.irishrail.ie/realtime/realtime.asmx"
    let session = URLSession.shared

    private func getData(pathComponent: String, completionHandler: @escaping (Data?) -> Void) {
        let url = URL(string: baseURL + pathComponent)!
        var request = URLRequest(url: url)
        request.httpMethod  = "get"

        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                completionHandler(nil)
                return
            }
            guard let data = data else {
                completionHandler(nil)
                return
            }
            completionHandler(data)
        })
        task.resume()
    }

    func fetchAllStations(completionHandler: @escaping (Data?) -> Void) {
        getData(pathComponent: "/getAllStationsXML", completionHandler: completionHandler)
    }

    func fetchTrainsFromSource(sourceCode: String, completionHandler: @escaping (Data?) -> Void) {
        getData(pathComponent: "/getStationDataByCodeXML?StationCode=\(sourceCode)", completionHandler: completionHandler)
    }

    func fetchTrainMovement(trainCode: String, trainDate: String, completionHandler: @escaping (Data?) -> Void) {
        getData(pathComponent: "/getTrainMovementsXML?TrainId=\(trainCode)&TrainDate=\(trainDate)", completionHandler: completionHandler)
    }
}

class SearchTrainInteractor: PresenterToInteractorProtocol {
    var _sourceStationCode = String()
    var _destinationStationCode = String()
    var presenter: InteractorToPresenterProtocol?
    private var serviceManager: ServiceManagable

    init(serviceManager: ServiceManagable = ServiceManager()) {
        self.serviceManager = serviceManager
    }

    func fetchallStations() {
        if Reach().isNetworkReachable() == true {
            serviceManager.fetchAllStations { (data) in
                guard let responseData = data else {
                    self.presenter!.showNoStationAvailabilityMessage()
                    return
                }

                let station = try? XMLDecoder().decode(Stations.self, from: responseData)
                self.presenter!.stationListFetched(list: station!.stationsList)
            }
        } else {
            self.presenter!.showNoInterNetAvailabilityMessage()
        }
    }

    func fetchTrainsFromSource(sourceCode: String, destinationCode: String) {
        _sourceStationCode = sourceCode
        _destinationStationCode = destinationCode

        if Reach().isNetworkReachable() {
            serviceManager.fetchTrainsFromSource(sourceCode: sourceCode) { (data) in
                guard let responseData = data else {
                    self.presenter!.showNoTrainAvailbilityFromSource()
                    return
                }
                let stationData = try? XMLDecoder().decode(StationData.self, from: responseData)

                if let _trainsList = stationData?.trainsList {
                    self.proceesTrainListforDestinationCheck(trainsList: _trainsList)
                } else {
                    self.presenter!.showNoTrainAvailbilityFromSource()
                }
            }
        } else {
            self.presenter!.showNoInterNetAvailabilityMessage()
        }
    }
    
    private func proceesTrainListforDestinationCheck(trainsList: [StationTrain]) {
        var _trainsList = trainsList
        let today = Date()
        let group = DispatchGroup()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateString = formatter.string(from: today)
        
        for index  in 0...trainsList.count-1 {
            group.enter()
            if Reach().isNetworkReachable() {
                serviceManager.fetchTrainMovement(trainCode: trainsList[index].trainCode,
                                                  trainDate: dateString) { movementsData in

                                                    let trainMovements = try? XMLDecoder().decode(TrainMovementsData.self, from: movementsData!)

                    if let _movements = trainMovements?.trainMovements {
                        let sourceIndex = _movements.firstIndex(where: {$0.locationCode.caseInsensitiveCompare(self._sourceStationCode) == .orderedSame})
                        let destinationIndex = _movements.firstIndex(where: {$0.locationCode.caseInsensitiveCompare(self._destinationStationCode) == .orderedSame})
                        let desiredStationMoment = _movements.filter{$0.locationCode.caseInsensitiveCompare(self._destinationStationCode) == .orderedSame}
                        let isDestinationAvailable = desiredStationMoment.count == 1

                        if isDestinationAvailable  && sourceIndex! < destinationIndex! {
                            _trainsList[index].destinationDetails = desiredStationMoment.first
                        }
                    }
                    group.leave()
                }
            } else {
                self.presenter!.showNoInterNetAvailabilityMessage()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            let sourceToDestinationTrains = _trainsList.filter{$0.destinationDetails != nil}
            self.presenter!.fetchedTrainsList(trainsList: sourceToDestinationTrains)
        }
    }
}
