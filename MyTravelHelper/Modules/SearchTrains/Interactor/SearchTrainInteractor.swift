//
//  SearchTrainInteractor.swift
//  MyTravelHelper
//
//  Created by Satish on 11/03/19.
//  Copyright © 2019 Sample. All rights reserved.
//

import Foundation
import XMLParsing
import Alamofire


protocol ServiceManagable {
    func fetchAllStations(completionHandler: @escaping (Data?) -> Void)
    func fetchTrainsFromSource(sourceCode: String, completionHandler: @escaping (Data?) -> Void)
    func fetchTrainMovement(trainCode: String, trainDate: String, completionHandler: @escaping (Data?) -> Void)
}

class ServiceManager: ServiceManagable {
    func fetchAllStations(completionHandler: @escaping (Data?) -> Void) {
        Alamofire.request("http://api.irishrail.ie/realtime/realtime.asmx/getAllStationsXML")
            .response { (response) in
                completionHandler(response.data)
        }
    }

    func fetchTrainsFromSource(sourceCode: String, completionHandler: @escaping (Data?) -> Void) {
        let urlString = "http://api.irishrail.ie/realtime/realtime.asmx/getStationDataByCodeXML?StationCode=\(sourceCode)"
        Alamofire.request(urlString).response { (response) in
            completionHandler(response.data)
        }
    }

    func fetchTrainMovement(trainCode: String, trainDate: String, completionHandler: @escaping (Data?) -> Void) {
          let _urlString = "http://api.irishrail.ie/realtime/realtime.asmx/getTrainMovementsXML?TrainId=\(trainCode)&TrainDate=\(trainDate)"
        Alamofire.request(_urlString).response { (response) in
            completionHandler(response.data)
        }
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
