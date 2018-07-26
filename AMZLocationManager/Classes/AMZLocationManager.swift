//
//  AMZLocationManager.swift
//  AppmazoKit
//
//  Created by James Hickman on 5/12/18.
//  Copyright © 2018 Appmazo, LLC. All rights reserved.
//

import UIKit
import CoreLocation

public class AMZLocationManager: NSObject {
    private let AMZLocationManagerShouldUseCustomLocationKey = "AMZLocationManagerShouldUseCustomLocationKey"
    private let AMZLocationManagerLastLocationLatitudeKey = "AMZLocationManagerLastLocationLatitudeKey"
    private let AMZLocationManagerLastLocationLongitudeKey = "AMZLocationManagerLastLocationLongitudeKey"

    private var locationManager = CLLocationManager()
    
    private(set) public var isLocationUpdating = false
    private(set) public var currentLocation: CLLocation?
    private(set) public var currentAddress: String?
    
    public var locationUpdatedBlock: ((CLLocation?) -> Void)?
    public var locationAuthorizationUpdatedBlock: ((CLAuthorizationStatus) -> Void)?

    public var useCustomLocation: Bool = false {
        didSet {
            UserDefaults.standard.set(useCustomLocation, forKey: AMZLocationManagerShouldUseCustomLocationKey)
            UserDefaults.standard.synchronize()
            startMonitoringLocationIfAuthorized()
        }
    }
    
    public var distanceFilter: Double = 1609.34 * 1.0 { // Meters x Miles
        didSet {
            locationManager.distanceFilter = distanceFilter
        }
    }

    public var desiredAccuracy = kCLLocationAccuracyHundredMeters {
        didSet {
            locationManager.desiredAccuracy = desiredAccuracy
        }
    }

    // MARK: - Init
    
    public override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.distanceFilter = distanceFilter
        locationManager.desiredAccuracy = desiredAccuracy
        useCustomLocation = UserDefaults.standard.bool(forKey: AMZLocationManagerShouldUseCustomLocationKey)
        startMonitoringLocationIfAuthorized()
    }
    
    // MARK: - AMZLocationManager
    
    // MARK: Permissions
    
    public func requestLocationPermission(_ authorizationStatus: CLAuthorizationStatus) -> Bool {
        guard CLLocationManager.authorizationStatus() == .notDetermined  else { return false }
        
        if authorizationStatus == .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
        return true
    }
    
    public func isLocationsAuthorized() -> Bool {
        return isLocationAuthorizedWhenInUse() || isLocationAuthorizedAlways()
    }
    
    public func isLocationAuthorizedWhenInUse() -> Bool {
        return CLLocationManager.authorizationStatus() == .authorizedWhenInUse
    }
    
    public func isLocationAuthorizedAlways() -> Bool {
        return CLLocationManager.authorizationStatus() == .authorizedAlways
    }
    
    // MARK: Location Tracking

    public func startMonitoringLocationIfAuthorized(_ completion: ((Error?) -> Void)? = nil) {
        if useCustomLocation || !isLocationsAuthorized() {
            isLocationUpdating = true
            if let lastLocation = lastLocation() {
                updateLocation(lastLocation)
                
                address(forLocation: lastLocation, completion: {[weak self] (addressString, error) in
                    if let error = error {
                        completion?(error)
                    } else {
                        self?.currentAddress = addressString
                    }
                    self?.isLocationUpdating = false
                    self?.locationUpdatedBlock?(lastLocation)
                })
            } else {
                isLocationUpdating = false
            }
        } else if isLocationsAuthorized() {
            isLocationUpdating = true
            locationManager.stopUpdatingLocation()
            locationManager.startUpdatingLocation()
        }
    }
    
    private func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    private func clearLocation() {
        updateLocation(nil)
        locationUpdatedBlock?(nil)
    }

    private func location(forAddress address: String, completion: @escaping (CLLocation?, String?, Error?) -> ()) {
        CLGeocoder().geocodeAddressString(address) { [weak self] (placemarks, error) in
            if let placemark = placemarks?.first, let correctedAddressString = self?.address(forPlacemark: placemark), let location = placemark.location {
                completion(location, correctedAddressString, nil)
            } else {
                completion(nil, nil, nil)
            }
        }
    }

    private func lastLocation() -> CLLocation? {
        if let latitude = UserDefaults.standard.value(forKey: AMZLocationManagerLastLocationLatitudeKey) as? Double, let longitude = UserDefaults.standard.value(forKey: AMZLocationManagerLastLocationLongitudeKey) as? Double {
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        
        return nil
    }
    
    private func updateLocation(_ location: CLLocation?) {
        currentLocation = location

        guard let location = location else {
            isLocationUpdating = false
            currentAddress = nil
            UserDefaults.standard.removeObject(forKey: AMZLocationManagerLastLocationLatitudeKey)
            UserDefaults.standard.removeObject(forKey: AMZLocationManagerLastLocationLongitudeKey)
            locationUpdatedBlock?(nil)
            return
        }
        
        UserDefaults.standard.set(location.coordinate.latitude, forKey: AMZLocationManagerLastLocationLatitudeKey)
        UserDefaults.standard.set(location.coordinate.longitude, forKey: AMZLocationManagerLastLocationLongitudeKey)
        UserDefaults.standard.synchronize()

        self.address(forLocation: location) { [weak self] (address, error) in
            self?.currentAddress = address
            self?.isLocationUpdating = false
            self?.locationUpdatedBlock?(location)
        }
    }
    
    public func updateLocation(forAddress address: String?, completion: @escaping (String?, CLLocation?, Error?) -> ()) {
        guard let address = address, address.count > 0 else {
            updateLocation(nil)
            return
        }
        
        location(forAddress: address) { [weak self] (location, correctedAddressString, error) in
            if let location = location {
                self?.currentAddress = correctedAddressString
                self?.updateLocation(location)
                completion(correctedAddressString, location, nil)
            } else {
                completion(nil, nil, error)
            }
        }
    }

    private func address(forLocation location: CLLocation, completion: @escaping (String?, Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {[weak self] (placemarks, error) -> Void in
            if let error = error {
                completion(nil, error)
            } else if let placemark = placemarks?.first {
                completion(self?.address(forPlacemark: placemark), nil)
            }
        })
    }

    private func address(forPlacemark placemark: CLPlacemark) -> String? {
        var address = ""
        if let city = placemark.locality, let state = placemark.administrativeArea, let postalCode = placemark.postalCode {
            address = city + ", " + state + ", " + postalCode
        } else if let city = placemark.locality, let state = placemark.administrativeArea {
            address = city + ", " + state
        } else if let city = placemark.administrativeArea {
            address = city
        } else if let postalCode = placemark.postalCode {
            address = postalCode
        }
        
        return address
    }
}

extension AMZLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status != .denied && status != .notDetermined else {
            stopUpdatingLocation()
            locationAuthorizationUpdatedBlock?(status)
            return
        }
        
        startMonitoringLocationIfAuthorized()
        locationAuthorizationUpdatedBlock?(status)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updateLocation(locations.first)
    }
}
