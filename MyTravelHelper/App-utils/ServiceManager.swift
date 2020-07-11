//
//  ServiceManager.swift
//  MyTravelHelper
//

import Foundation

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
