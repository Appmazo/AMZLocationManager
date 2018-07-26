//
//  ExampleTableViewController.swift
//  AMZLocationManager_Example
//
//  Created by James Hickman on 7/25/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import AppmazoUIKit
import AMZLocationManager
import AMZAlertController

class ExampleTableViewController: UITableViewController {
    private enum LocationManagerTableViewControllerSection: Int {
        case location
        case count
    }
    
    private enum LocationManagerTableViewControllerLocationRow: Int {
        case currentLocation
        case locationAddress
        case count
    }
    
    private let locationManager = AMZLocationManager()
    
    // MARK: - UITableViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "AMZLocationManager"
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
        tableView.register(PermissionPromptTableViewCell.self, forCellReuseIdentifier: PermissionPromptTableViewCell.reuseIdentifier)
        tableView.register(LocationTableViewCell.self, forCellReuseIdentifier: LocationTableViewCell.reuseIdentifier)
        
        locationManager.locationAuthorizationUpdatedBlock = { (authorizationStatus) in
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
        
        locationManager.locationUpdatedBlock = { (location) in
            DispatchQueue.main.async { [weak self] in
                if location != nil { // Don't reload when clearing existing text or it will end editing.
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - LocationManagerTableViewController
    
    private func locationCellForIndexPath(_ indexPath: IndexPath) -> UITableViewCell {
        if locationManager.isLocationsAuthorized() {
            switch indexPath.row {
            case LocationManagerTableViewControllerLocationRow.currentLocation.rawValue:
                let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
                cell.selectionStyle = .none
                cell.textLabel?.text = "Use Current Location"
                
                let locationSwitch = UISwitch()
                locationSwitch.isOn = !locationManager.useCustomLocation
                locationSwitch.addTarget(self, action: #selector(locationSwitchUpdated(_:)), for: .valueChanged)
                cell.accessoryView = locationSwitch
                return cell
            case LocationManagerTableViewControllerLocationRow.locationAddress.rawValue:
                if let cell = tableView.dequeueReusableCell(withIdentifier: LocationTableViewCell.reuseIdentifier, for: indexPath) as? LocationTableViewCell {
                    cell.delegate = self
                    
                    if locationManager.isLocationUpdating {
                        cell.locationText = "Updating your location..."
                        cell.state = .loading
                    } else if locationManager.currentLocation == nil {
                        cell.locationText = locationManager.currentAddress
                        cell.state = .customLocation
                    } else if locationManager.currentLocation != nil {
                        cell.locationText = locationManager.currentAddress
                        if locationManager.useCustomLocation || !locationManager.isLocationsAuthorized() {
                            cell.state = .customLocation
                        } else {
                            cell.state = .userLocation
                        }
                    }
                    
                    return cell
                }
            default:
                break
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: PermissionPromptTableViewCell.reuseIdentifier, for: indexPath) as? PermissionPromptTableViewCell {
                cell.delegate = self
                cell.permissionType = .locationAlways
                cell.enabled = !locationManager.isLocationsAuthorized()
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    @objc private func locationSwitchUpdated(_ sender: UISwitch) {
        locationManager.useCustomLocation = !sender.isOn
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return LocationManagerTableViewControllerSection.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case LocationManagerTableViewControllerSection.location.rawValue:
            return locationManager.isLocationsAuthorized() ? 2 : 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        switch indexPath.section {
        case LocationManagerTableViewControllerSection.location.rawValue:
            cell = locationCellForIndexPath(indexPath)
        default:
            cell = UITableViewCell()
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
}

extension ExampleTableViewController: PermissionPromptTableViewCellDelegate {
    func permissionPromptTableViewCell(_ permissionPromptTableViewCell: PermissionPromptTableViewCell, buttonPressed: Button) {
        if !locationManager.requestLocationPermission(.authorizedAlways) {
            let alertViewController = AlertController.alertControllerWithTitle("Uh-Oh", message: "Looks like you already set the location permissions.\n\nYou can update the authorization in Settings.")
            alertViewController.addAction(AlertAction(withTitle: "Go to Settings", style: .filled, handler: { (alertAction) in
                UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!, options:[:], completionHandler:nil)
            }))
            alertViewController.addAction(AlertAction(withTitle: "Maybe Later", style: .normal, handler: nil))
            present(alertViewController, animated: true, completion: nil)
        }
    }
}

extension ExampleTableViewController: LocationTableViewCellDelegate {
    func locationTableViewCell(_ locationTableViewCell: LocationTableViewCell, locationTextUpdated locationText: String?) {
        locationManager.updateLocation(forAddress: locationText) { (correctedAddress, location, error) in
            DispatchQueue.main.async { [weak self] in
                if locationText != nil { // Don't reload when clearing existing text or it will end editing.
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    func locationTableViewCell(_ locationTableViewCell: LocationTableViewCell, locationButtonPressed locationButton: Button) {
        locationTableViewCell.state = .loading
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: { // Add delay for smooth loading UI.
            self.locationManager.startMonitoringLocationIfAuthorized()
        })
    }
}
