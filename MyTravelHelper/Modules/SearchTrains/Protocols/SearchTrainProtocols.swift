//
//  SearchTrainProtocols.swift
//  MyTravelHelper
//
//  Created by Satish on 11/03/19.
//  Copyright © 2019 Sample. All rights reserved.
//

import UIKit

protocol ViewToPresenterProtocol: class{
    var view: PresenterToViewProtocol? {get set}
    var interactor: PresenterToInteractorProtocol? {get set}
    var router: PresenterToRouterProtocol? {get set}
    func fetchallStations()
    func searchTapped(source:String,destination:String)
    func saveFavouriteStation(isSourceStation: Bool, stationName: String)
    func loadFavouriteStation(callback: (String, String) -> Void)
}

protocol PresenterToViewProtocol: class{
    func saveFetchedStations(stations:[Station]?)
    func showInvalidSourceOrDestinationAlert()
    func updateLatestTrainList(trainsList: [StationTrain])
    func showNoTrainsFoundAlert()
    func showNoTrainAvailbilityFromSource()
    func showNoInterNetAvailabilityMessage()
    func showNoStationAvailabilityMessage()
}

protocol PresenterToRouterProtocol: class {
    static func createModule()-> SearchTrainViewController
}

protocol PresenterToInteractorProtocol: class {
    var presenter:InteractorToPresenterProtocol? {get set}
    func fetchAllStations()
    func fetchTrainsFromSource(sourceCode:String,destinationCode:String)
    func saveFavouriteStation(isSourceStation: Bool, stationName: String)
    func loadFavouriteStation(callback: (String, String) -> Void)
}

protocol InteractorToPresenterProtocol: class {
    func stationListFetched(list:[Station])
    func fetchedTrainsList(trainsList:[StationTrain]?)
    func showNoTrainAvailbilityFromSource()
    func showNoInterNetAvailabilityMessage()
    func showNoStationAvailabilityMessage()

}
