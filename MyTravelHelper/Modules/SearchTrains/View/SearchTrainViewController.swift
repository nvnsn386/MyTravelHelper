//
//  SearchTrainViewController.swift
//  MyTravelHelper
//
//  Created by Satish on 11/03/19.
//  Copyright © 2019 Sample. All rights reserved.
//

import UIKit
import SwiftSpinner
import DropDown

class SearchTrainViewController: UIViewController {
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var sourceTxtField: UITextField!
    @IBOutlet weak var trainsListTable: UITableView!

    var stationsList:[Station] = [Station]()
    var trains:[StationTrain] = [StationTrain]()
    var presenter:ViewToPresenterProtocol?
    var dropDown = DropDown()
    var transitPoints:(source:String,destination:String) = ("","")

    override func viewDidLoad() {
        super.viewDidLoad()
        trainsListTable.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if stationsList.count == 0 {
            SwiftSpinner.useContainerView(view)
            SwiftSpinner.show("Please wait loading station list ....")
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.presenter?.fetchallStations()
            }
        }
    }

    @IBAction func searchTrainsTapped(_ sender: Any) {
        view.endEditing(true)
        showProgressIndicator(view: self.view)
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.presenter?.searchTapped(source: self.transitPoints.source,
                                         destination: self.transitPoints.destination)
        }
    }
}

extension SearchTrainViewController:PresenterToViewProtocol {
    func showNoInterNetAvailabilityMessage() {
        DispatchQueue.main.async { [weak self] in
            self?.showwAlert("No Internet", description: "Please Check you internet connection and try again")
        }
    }

    func showNoStationAvailabilityMessage() {
        DispatchQueue.main.async { [weak self] in
            self?.showwAlert("No Station", description: "Please try again!")
        }
    }

    private func showwAlert(_ title: String, description: String) {
        hideProgressIndicator(view: self.view)
        trainsListTable.isHidden = true
        showAlert(title: title, message: description, actionTitle: "Okay")
    }

    func showNoTrainAvailbilityFromSource() {
        DispatchQueue.main.async { [weak self] in
            self?.showwAlert("No Trains", description: "Sorry No trains arriving source station in another 90 mins")
        }
    }

    func updateLatestTrainList(trainsList: [StationTrain]) {
        trains = trainsList
        hideProgressIndicator(view: self.view)
        if trainsList.count == 0 {
            DispatchQueue.main.async { [weak self] in
                self?.showwAlert("No Trains", description: "Sorry No trains arriving source station in another 90 mins")
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.trainsListTable.isHidden = false
            self.trainsListTable.reloadData()
        }
    }

    func showNoTrainsFoundAlert() {
        trainsListTable.isHidden = true
        hideProgressIndicator(view: self.view)
        trainsListTable.isHidden = true
        showAlert(title: "No Trains",
                  message: "Sorry No trains Found from source to destination in another 90 mins",
                  actionTitle: "Okay")
    }

    func showAlert(title:String,message:String,actionTitle:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func showInvalidSourceOrDestinationAlert() {
        trainsListTable.isHidden = true
        hideProgressIndicator(view: self.view)
        showAlert(title: "Invalid Source/Destination",
                  message: "Invalid Source or Destination Station names Please Check",
                  actionTitle: "Okay")
    }

    func saveFetchedStations(stations: [Station]?) {
        if let _stations = stations {
            self.stationsList = _stations
        }
        DispatchQueue.main.async {
            SwiftSpinner.hide()
        }
    }
}

extension SearchTrainViewController:UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        dropDown = DropDown()
        dropDown.anchorView = textField
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
        dropDown.dataSource = stationsList.map {$0.stationDesc}
        dropDown.selectionAction = { (index: Int, item: String) in
            if textField == self.sourceTxtField {
                self.transitPoints.source = item
            }else {
                self.transitPoints.destination = item
            }
            textField.text = item
        }
        dropDown.show()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dropDown.hide()
        return textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let inputedText = textField.text {
            var desiredSearchText = inputedText
            if string != "\n" && !string.isEmpty{
                desiredSearchText = desiredSearchText + string
            }else {
                desiredSearchText = String(desiredSearchText.dropLast())
            }

            dropDown.dataSource = getStationNameList()
            dropDown.show()
            dropDown.reloadAllComponents()
        }
        return true
    }

    private func getStationNameList() -> [String] {
        return stationsList.map({ $0.stationDesc })
    }
}

extension SearchTrainViewController:UITableViewDataSource,UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trains.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "train", for: indexPath) as! TrainInfoCell
        let train = trains[indexPath.row]
        cell.trainCode.text = train.trainCode
        cell.souceInfoLabel.text = train.stationFullName
        cell.sourceTimeLabel.text = train.expDeparture
        if let _destinationDetails = train.destinationDetails {
            cell.destinationInfoLabel.text = _destinationDetails.locationFullName
            cell.destinationTimeLabel.text = _destinationDetails.expDeparture
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}
