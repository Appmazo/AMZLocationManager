//
//  ExampleTableViewController.swift
//  AMZLocationManager_Example
//
//  Created by James Hickman on 7/25/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import AMZLocationManager

import AppmazoUIKit
import AMZAlertController

class ExampleTableViewController: UITableViewController {
    private enum ExampleTableViewControllerSection: Int {
        case location
        case count
    }
    
    private enum ExampleTableViewControllerLocationRow: Int {
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
    
    // MARK: - ExampleTableViewController
    
    private func locationCellForIndexPath(_ indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case ExampleTableViewControllerLocationRow.currentLocation.rawValue:
            if locationManager.isLocationsAuthorized() {
                let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
                cell.selectionStyle = .none
                cell.textLabel?.text = "Use Current Location"
                
                let locationSwitch = UISwitch()
                locationSwitch.isOn = !locationManager.useCustomLocation
                locationSwitch.addTarget(self, action: #selector(locationSwitchUpdated(_:)), for: .valueChanged)
                cell.accessoryView = locationSwitch
                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: PermissionPromptTableViewCell.reuseIdentifier, for: indexPath) as? PermissionPromptTableViewCell else { return UITableViewCell() }
                cell.delegate = self
                cell.permissionType = .locationAlways
                cell.enabled = !locationManager.isLocationAuthorizedAlways()
                return cell
            }
        case ExampleTableViewControllerLocationRow.locationAddress.rawValue:
            if locationManager.isLocationsAuthorized() {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: LocationTableViewCell.reuseIdentifier, for: indexPath) as? LocationTableViewCell else { return UITableViewCell() }
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
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: PermissionPromptTableViewCell.reuseIdentifier, for: indexPath) as? PermissionPromptTableViewCell else { return UITableViewCell() }
                cell.delegate = self
                cell.permissionType = .locationWhenInUse
                cell.enabled = !locationManager.isLocationAuthorizedWhenInUse()
                return cell
            }
        default:
            return UITableViewCell()
        }
    }
    
    @objc private func locationSwitchUpdated(_ sender: UISwitch) {
        locationManager.useCustomLocation = !sender.isOn
        tableView.reloadData()
    }
    
    private func showAuthorizationAlreadySetAlert() {
        let alertViewController = AMZAlertController.alertControllerWithTitle("Uh-Oh", message: "Looks like you already set the location permissions.\n\nYou can update the authorization in Settings.")
        alertViewController.addAction(AMZAlertAction(withTitle: "Go to Settings", style: .filled, handler: { (alertAction) in
            UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!, options:[:], completionHandler:nil)
        }))
        alertViewController.addAction(AMZAlertAction(withTitle: "Maybe Later", style: .normal, handler: nil))
        present(alertViewController, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return ExampleTableViewControllerSection.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case ExampleTableViewControllerSection.location.rawValue:
            return ExampleTableViewControllerLocationRow.count.rawValue
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return locationCellForIndexPath(indexPath)
    }
}

extension ExampleTableViewController: PermissionPromptTableViewCellDelegate {
    func permissionPromptTableViewCell(_ permissionPromptTableViewCell: PermissionPromptTableViewCell, buttonPressed: Button) {
        
        if permissionPromptTableViewCell.permissionType == .locationAlways && !locationManager.requestLocationAlwaysPermission() {
            showAuthorizationAlreadySetAlert()
        } else if permissionPromptTableViewCell.permissionType == .locationWhenInUse && !locationManager.requestLocationWhenInUsePermission() {
            showAuthorizationAlreadySetAlert()
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
            self.locationManager.startMonitoringLocation()
        })
    }
}
