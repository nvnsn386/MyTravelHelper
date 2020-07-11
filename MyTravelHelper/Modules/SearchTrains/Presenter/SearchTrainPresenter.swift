//
//  SearchTrainPresenter.swift
//  MyTravelHelper
//
//  Created by Satish on 11/03/19.
//  Copyright © 2019 Sample. All rights reserved.
//

import UIKit

class SearchTrainPresenter:ViewToPresenterProtocol {
    var stationsList:[Station] = [Station]()

    func searchTapped(source: String, destination: String) {
        let sourceStationCode = getStationCode(stationName: source)
        let destinationStationCode = getStationCode(stationName: destination)
        interactor?.fetchTrainsFromSource(sourceCode: sourceStationCode, destinationCode: destinationStationCode)
    }
    
    var interactor: PresenterToInteractorProtocol?
    var router: PresenterToRouterProtocol?
    var view:PresenterToViewProtocol?

    func fetchallStations() {
        interactor?.fetchAllStations()
    }

    private func getStationCode(stationName:String)->String {
        let stationCode = stationsList.filter{$0.stationDesc == stationName}.first
        return stationCode?.stationCode.lowercased() ?? ""
    }

    func saveFavouriteStation(isSourceStation: Bool, stationName: String) {
        interactor?.saveFavouriteStation(isSourceStation: isSourceStation, stationName: stationName)
    }

    func loadFavouriteStation(callback: (String, String) -> Void) {
        interactor?.loadFavouriteStation(callback: callback)
    }
}

extension SearchTrainPresenter: InteractorToPresenterProtocol {
    func showNoInterNetAvailabilityMessage() {
        view!.showNoInterNetAvailabilityMessage()
    }

    func showNoTrainAvailbilityFromSource() {
        view!.showNoTrainAvailbilityFromSource()
    }

    func fetchedTrainsList(trainsList: [StationTrain]?) {
        if let _trainsList = trainsList {
            view!.updateLatestTrainList(trainsList: _trainsList)
        }else {
            view!.showNoTrainsFoundAlert()
        }
    }
    
    func stationListFetched(list: [Station]) {
        stationsList = list
        view!.saveFetchedStations(stations: list)
    }

    func showNoStationAvailabilityMessage() {
        view!.showNoStationAvailabilityMessage()
    }
}
