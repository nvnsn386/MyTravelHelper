//
//  SearchTrainInteractorTests.swift
//  MyTravelHelperTests
//

import XCTest
@testable import MyTravelHelper

class SearchTrainInteractorTests: XCTestCase {
    let presenter = SearchTrainPresenterMock()
    var subject: SearchTrainInteractor!
    let serviceManagerMock = ServiceManagerMock()
    let reachabiliityMock = ReachablityMock()
    let xmlDecoder = XMLDecoderMock()

    override func setUp() {
        subject = SearchTrainInteractor(serviceManager: serviceManagerMock, reachablity: reachabiliityMock,
                                        xmlDecoder: xmlDecoder)
        subject.presenter = presenter
    }

    func testfetchAllStationsWhenNoInternet() {
        reachabiliityMock.isAvailable = false
        subject.fetchAllStations()
        XCTAssertTrue(presenter.isNoInterNetAvailabilityCalled)
    }

    func testfetchAllStationWhenResponseDataIsNil() {
        reachabiliityMock.isAvailable = true
        serviceManagerMock.resposeData = nil
        subject.fetchAllStations()
        XCTAssertTrue(presenter.isNoStationAvailabilityCalled)
    }

    func testfetchAllStationWhenResponseDataExists() {
        reachabiliityMock.isAvailable = true
        serviceManagerMock.resposeData = Data()
        subject.fetchAllStations()
        XCTAssertTrue(presenter.stationList.count == 1)
        let station = presenter.stationList.first
        XCTAssertTrue(station?.stationDesc == "Belfast")
        XCTAssertTrue(station?.stationLatitude == 54.6123)
        XCTAssertTrue(station?.stationLongitude == -5.91744)
        XCTAssertTrue(station?.stationCode == "BFSTC")
        XCTAssertTrue(station?.stationId == 228)
    }

    func testfetchTrainBetweenSourceAndDestinationWhenNoInternet() {
        reachabiliityMock.isAvailable = false
        subject.fetchTrainsFromSource(sourceCode: "Belfast", destinationCode: "Lisburn")
        XCTAssertTrue(presenter.isNoInterNetAvailabilityCalled)
    }

    func testfetchTrainBetweenSourceAndDestinationWhenDataIsNil() {
        reachabiliityMock.isAvailable = true
        serviceManagerMock.resposeData = nil
        subject.fetchTrainsFromSource(sourceCode: "Belfast", destinationCode: "Lisburn")
        XCTAssertTrue(presenter.isNoTrainAvailabilityCalled)
    }

    func testfetchTrainBetweenSourceAndDestinationWhenTrainListIsEmpty() {
        reachabiliityMock.isAvailable = true
        serviceManagerMock.resposeData = Data()
        xmlDecoder.isTrainListEmpty = true
        subject.fetchTrainsFromSource(sourceCode: "Belfast", destinationCode: "Lisburn")
        XCTAssertTrue(presenter.isNoTrainAvailabilityCalled)
    }

    func testfetchTrainBetweenSourceAndDestinationWhenNoDestinationDetails() {
        reachabiliityMock.isAvailable = true
        serviceManagerMock.resposeData = Data()
        xmlDecoder.isTrainListEmpty = false
        subject.fetchTrainsFromSource(sourceCode: "Belfast", destinationCode: "Lisburn")
        XCTAssertTrue(serviceManagerMock.fetchTrainMovementCalled)
        XCTAssertTrue(presenter.stationTrainList.count == 0)
    }

    func testfetchTrainBetweenSourceAndDestinationWithDestinationDetails() {
           reachabiliityMock.isAvailable = true
           serviceManagerMock.resposeData = Data()
            xmlDecoder.isTrainListEmpty = false
           xmlDecoder.isTrainMovementListEmpty = false
           subject.fetchTrainsFromSource(sourceCode: "Belfast", destinationCode: "Lisburn")
           XCTAssertTrue(serviceManagerMock.fetchTrainMovementCalled)
           XCTAssertTrue(presenter.stationTrainList.count == 0)
       }

    override func tearDown() {
        subject = nil
    }
}

class XMLDecoderMock: XMLDecodable {
    let station = Station(desc: "Belfast", latitude: 54.6123, longitude: -5.91744, code: "BFSTC", stationId: 228)
    var train = StationTrain(trainCode: "A129",
                             fullName: "Portadown",
                             stationCode: "PDOWN",
                             trainDate: "11 Jul 2020",
                             dueIn: 34,
                             lateBy: 0,
                             expArrival: "14:39",
                             expDeparture: "14:42")
    let trainMovement = TrainMovement(trainCode: "A129", locationCode: "BFSTC", locationFullName: "Xasdas", expDeparture: "Portadown")
    var isTrainListEmpty = true
    var isTrainMovementListEmpty = true

    func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T {
        if type == Stations.self {
            return Stations(stationsList: [station]) as! T
        } else if type == StationData.self {
            if isTrainListEmpty {
                return StationData(trainsList: []) as! T
            } else {
                if isTrainMovementListEmpty {
                return StationData(trainsList: [train]) as! T
                } else {
                    train.destinationDetails = trainMovement
                    return StationData(trainsList: [train]) as! T
                }
            }
        } else if type == TrainMovementsData.self {
            if isTrainMovementListEmpty {
                return TrainMovementsData(trainMovements: []) as! T
            } else {
                return TrainMovementsData(trainMovements: [trainMovement]) as! T
            }
        }
        return TrainMock() as! T
    }
}

class TrainMock {}

class SearchTrainPresenterMock: InteractorToPresenterProtocol {
    var stationList = [Station]()
    var stationTrainList = [StationTrain]()

    func stationListFetched(list:[Station]) {
        stationList = list
    }

    func fetchedTrainsList(trainsList:[StationTrain]?) {
        stationTrainList = trainsList!
    }

    var isNoTrainAvailabilityCalled = false

    func showNoTrainAvailbilityFromSource() {
        isNoTrainAvailabilityCalled = true
    }

    var isNoInterNetAvailabilityCalled = false
    var isNoStationAvailabilityCalled = false

    func showNoInterNetAvailabilityMessage() {
        isNoInterNetAvailabilityCalled = true
    }

    func showNoStationAvailabilityMessage() {
        isNoStationAvailabilityCalled = true
    }
}

class ServiceManagerMock: ServiceManagable {
    var resposeData: Data?
    func fetchAllStations(completionHandler: @escaping (Data?) -> Void) {
        completionHandler(resposeData)
    }

    func fetchTrainsFromSource(sourceCode: String, completionHandler: @escaping (Data?) -> Void) {
        completionHandler(resposeData)
    }

    var fetchTrainMovementCalled = false

    func fetchTrainMovement(trainCode: String, trainDate: String, completionHandler: @escaping (Data?) -> Void) {
        fetchTrainMovementCalled = true
        completionHandler(resposeData)
    }
}

class ReachablityMock: Reachable {
    var isAvailable = true

    func isNetworkReachable() -> Bool {
        return isAvailable
    }
}
