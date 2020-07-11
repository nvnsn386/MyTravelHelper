//
//  SearchTrainInteractor.swift
//  MyTravelHelper
//
//  Created by Satish on 11/03/19.
//  Copyright © 2019 Sample. All rights reserved.
//

import Foundation
import XMLParsing

protocol XMLDecodable {
    func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension XMLDecoder: XMLDecodable {}

class SearchTrainInteractor: PresenterToInteractorProtocol {
    var _sourceStationCode = String()
    var _destinationStationCode = String()
    var presenter: InteractorToPresenterProtocol?
    private var serviceManager: ServiceManagable
    private var reachablity: Reachable
    private var xmlDecoder: XMLDecodable
    private let userDefaults = UserDefaults.standard

    init(serviceManager: ServiceManagable = ServiceManager(),
         reachablity: Reachable = Reach(),
         xmlDecoder: XMLDecodable = XMLDecoder()) {
        self.serviceManager = serviceManager
        self.reachablity = reachablity
        self.xmlDecoder = xmlDecoder
    }

    func saveFavouriteStation(isSourceStation: Bool, stationName: String) {
        if isSourceStation {
            userDefaults.setValue(stationName, forKey: favouriteSourceKey)
        } else {
            userDefaults.setValue(stationName, forKey: favouriteDestinationKey)
        }
    }

    func loadFavouriteStation(callback: (String, String) -> Void) {
        var sourceStation = ""
        var destinationStation = ""
        if let source = userDefaults.value(forKey: favouriteSourceKey) as? String {
            sourceStation = source
        }
        if let destination = userDefaults.value(forKey: favouriteDestinationKey) as? String {
            destinationStation = destination
        }
        callback(sourceStation, destinationStation)
    }

    func fetchAllStations() {
        if reachablity.isNetworkReachable() {
            serviceManager.fetchAllStations { [weak self] (data) in

                guard let responseData = data else {
                    self?.presenter!.showNoStationAvailabilityMessage()
                    return
                }
                self?.handleAllStationResponse(responseData: responseData)
            }
        } else {
            self.presenter!.showNoInterNetAvailabilityMessage()
        }
    }

    private func handleAllStationResponse(responseData: Data) {
        do {
            let station = try xmlDecoder.decode(Stations.self, from: responseData)
            presenter!.stationListFetched(list: station.stationsList)
        } catch (let error) {
            presenter!.showNoStationAvailabilityMessage()
            print(error)
        }
    }

    private func handleSourceStationResponse(responseData: Data) {
        do {
            let stationData = try xmlDecoder.decode(StationData.self, from: responseData)
            if stationData.trainsList.count == 0 {
                presenter!.showNoTrainAvailbilityFromSource()
            } else {
                proceesTrainListforDestinationCheck(trainsList: stationData.trainsList)
            }
        } catch (let error) {
            presenter!.showNoTrainAvailbilityFromSource()
            print(error)
        }
    }

    func fetchTrainsFromSource(sourceCode: String, destinationCode: String) {
        _sourceStationCode = sourceCode
        _destinationStationCode = destinationCode

        if reachablity.isNetworkReachable() {
            serviceManager.fetchTrainsFromSource(sourceCode: sourceCode) { [weak self]  (data) in
                guard let responseData = data else {
                    self?.presenter!.showNoTrainAvailbilityFromSource()
                    return
                }
                self?.handleSourceStationResponse(responseData: responseData)
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
            if reachablity.isNetworkReachable() {
                serviceManager.fetchTrainMovement(trainCode: trainsList[index].trainCode,
                                                  trainDate: dateString) { [weak self] movementsData in
                                                    guard let self = self else { return }

                                                    let trainMovements = try? self.xmlDecoder.decode(TrainMovementsData.self, from: movementsData!)

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
