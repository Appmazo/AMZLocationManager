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
            useCustomLocation ? locationManager.stopUpdatingLocation() : startMonitoringLocation()
        }
    }
    
    /**
     The radius in miles the user must move in order for their location to be updated.
     */
    public var distanceFilter: Double = 1609.34 * 1.0 { // Meters x Miles
        didSet {
            locationManager.distanceFilter = distanceFilter
        }
    }

    /**
     The desired accuracy of the user's location.
     
     **Default**
    
     kCLLocationAccuracyHundredMeters
     */
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
        
        if canUseLocationTracking() {
            startMonitoringLocation()
        } else if let lastLocation = lastLocation() {
            updateLocation(lastLocation)
        }
    }
    
    // MARK: - AMZLocationManager
    
    // MARK: Permissions
    
    /**
     Requests authorization for location services always.
     
     - returns: true if successful request, false if the user had already approved/denied authorization.
     */
    public func requestLocationAlwaysPermission() -> Bool {
        return requestLocationPermission(.authorizedAlways)
    }
    
    /**
     Requests authorization for location services when in use.
     
     - returns: true if successful request, false if the user had already approved/denied authorization.
     */
    public func requestLocationWhenInUsePermission() -> Bool {
        return requestLocationPermission(.authorizedWhenInUse)
    }
    
    /**
     Requests authorization for location services.
     
     - parameters:
        - authorizationStatus: The preferred CLAuthorizationStatus.

     - returns: Bool
     */
    private func requestLocationPermission(_ authorizationStatus: CLAuthorizationStatus) -> Bool {
        guard CLLocationManager.authorizationStatus() == .notDetermined  else { return false }
        
        if authorizationStatus == .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
        return true
    }
    
    /**
     Determines if the user has authorized any location services.
     
     - returns: Bool
     */
    public func isLocationsAuthorized() -> Bool {
        return isLocationAuthorizedWhenInUse() || isLocationAuthorizedAlways()
    }
    
    /**
     Determines if the user has authorized location services when in use.
     
     - returns: Bool
     */
    public func isLocationAuthorizedWhenInUse() -> Bool {
        return CLLocationManager.authorizationStatus() == .authorizedWhenInUse
    }
    
    /**
     Determines if the user has authorized location services always.
     
     - returns: Bool
     */
    public func isLocationAuthorizedAlways() -> Bool {
        return CLLocationManager.authorizationStatus() == .authorizedAlways
    }
    
    // MARK: Location Tracking

    /**
     Determines if the user has authorized location services and want to use their current location.
     
     - returns: Bool
     */
    private func canUseLocationTracking() -> Bool {
        return isLocationsAuthorized() && !useCustomLocation
    }
    
    /**
     Starts monitoring the user's location if authorized and not using custom location.
     */
    public func startMonitoringLocation() {
        if canUseLocationTracking() {
            isLocationUpdating = true
            locationManager.stopUpdatingLocation()
            locationManager.startUpdatingLocation()
        }
    }
    
    /**
     Clears the location data.
     */
    private func clearLocation() {
        updateLocation(nil)
        locationUpdatedBlock?(nil)
    }

    /**
     Retrieve a location from a provided address.
     
     - parameters:
        - address: The address string.
        - completion: The completion handler once the location is generated.
     */
    private func location(forAddress address: String, completion: @escaping (CLLocation?, String?, Error?) -> ()) {
        CLGeocoder().geocodeAddressString(address) { [weak self] (placemarks, error) in
            if let placemark = placemarks?.first, let correctedAddressString = self?.address(forPlacemark: placemark), let location = placemark.location {
                completion(location, correctedAddressString, nil)
            } else {
                completion(nil, nil, nil)
            }
        }
    }

    /**
     Get the last known location of the user.
     
     - returns: CLLocation
     */
    private func lastLocation() -> CLLocation? {
        if let latitude = UserDefaults.standard.value(forKey: AMZLocationManagerLastLocationLatitudeKey) as? Double, let longitude = UserDefaults.standard.value(forKey: AMZLocationManagerLastLocationLongitudeKey) as? Double {
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        
        return nil
    }
    
    /**
     Update the current location of the user.
     
     - parameters:
        - location: CLLocation
     */
    private func updateLocation(_ location: CLLocation?) {
        currentLocation = location

        guard let location = location else {
            isLocationUpdating = false
            currentAddress = nil
            UserDefaults.standard.removeObject(forKey: AMZLocationManagerLastLocationLatitudeKey)
            UserDefaults.standard.removeObject(forKey: AMZLocationManagerLastLocationLongitudeKey)
            UserDefaults.standard.synchronize()
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
    
    /**
     Update the current location of the user.
     
    - parameters:
        - address: String
        - completion: (String?, CLLocation?, Error?)
     */
    public func updateLocation(forAddress address: String?, completion: @escaping (String?, CLLocation?, Error?) -> ()) {
        guard let address = address, address.count > 0 else {
            updateLocation(nil)
            completion(nil, nil, nil)
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

    /**
     Fetch the address for a provided location.
     
     - parameters:
        - location: CLLocation
        - completion: (String?, Error?)
     */
    private func address(forLocation location: CLLocation, completion: @escaping (String?, Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {[weak self] (placemarks, error) -> Void in
            if let error = error {
                completion(nil, error)
            } else if let placemark = placemarks?.first {
                completion(self?.address(forPlacemark: placemark), nil)
            }
        })
    }

    /**
     Fetch the address for a provided CLPlacemark.
     
     - parameters:
        - placemark: CLPlacemark
     
     - returns: String?
     */
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
            locationManager.stopUpdatingLocation()
            locationAuthorizationUpdatedBlock?(status)
            return
        }
        
        startMonitoringLocation()
        locationAuthorizationUpdatedBlock?(status)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !useCustomLocation {
            updateLocation(locations.first)
        }
    }
}
