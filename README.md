# AMZLocationManager

[![CI Status](https://img.shields.io/travis/Appmazo/AMZLocationManager.svg?style=flat)](https://travis-ci.org/Appmazo/AMZLocationManager)
[![Version](https://img.shields.io/cocoapods/v/AMZLocationManager.svg?style=flat)](https://cocoapods.org/pods/AMZLocationManager)
[![License](https://img.shields.io/cocoapods/l/AMZLocationManager.svg?style=flat)](https://cocoapods.org/pods/AMZLocationManager)
[![Platform](https://img.shields.io/cocoapods/p/AMZLocationManager.svg?style=flat)](https://cocoapods.org/pods/AMZLocationManager)
[![Beerpay](https://beerpay.io/Appmazo/AMZLocationManager/badge.svg)](https://beerpay.io/Appmazo/AMZLocationManager)
[![Beerpay](https://beerpay.io/Appmazo/AMZLocationManager/make-wish.svg)](https://beerpay.io/Appmazo/AMZLocationManager)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS 11.0+

## Installation

AMZLocationManager is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AMZLocationManager'
```

# Usage

### Setup

```swift
let locationManager = AMZLocationManager()
```

### Observe Authorization Status Changes

```swift
locationManager.locationAuthorizationUpdatedBlock = { (authorizationStatus) in
    DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
    }
}
```

### Observe Location Changes
```swift
locationManager.locationUpdatedBlock = { (location) in
    DispatchQueue.main.async { [weak self] in
        if location != nil { // Don't reload when clearing existing text or it will end editing.
            self?.tableView.reloadData()
        }
    }
}
```

### Properties

```isLocationUpdating ```: Returns true if the locationManager is updating the location. _(Read-Only)_

```currentLocation ```: Returns the user's current or custom CLLocation. _(Read-Only)_

```currentAddress ```: Returns the address for the user's current or custom CLLocation. _(Read-Only)_

```useCustomLocation```: Toggle this property if you want to use a custom location. _(i.e. Allowing the user to enter an address)_

```distanceFilter```: Change this property to determine the radius in miles for which a user must move for locations to update. _(Default: 1 mile)_

```desiredAccuracy```: Change this property to determine the accuracy for which a user's location should be tracked. _(Default: kCLLocationAccuracyHundredMeters)_

### Functions

Requests the location always permission using the native iOS prompt.

```swift
func requestLocationAlwaysPermission() -> Bool
```

Requests the location when in use permission using the native iOS prompt.

```swift
func requestLocationWhenInUsePermission() -> Bool
```

Returns true if the user has authorized to use location always or location when in use permissions.

```swift
func isLocationsAuthorized() -> Bool
```

Returns true if the user has authorized to use location always permissions.

```swift
func isLocationAuthorizedAlways() -> Bool
```

Returns true if the user has authorized to use location when in use permission.

```swift
func isLocationAuthorizedWhenInUse() -> Bool
```

Starts monitoring the user's location if authorized and not using custom location.

```swift
func startMonitoringLocation() -> Bool
```

Updates the current location of the user based on the provided address.

```swift
func updateLocation(forAddress address: String?, completion: @escaping (String?, CLLocation?, Error?) -> ())
```

## Author

Appmazo LLC, jhickman@appmazo.com

## License

AMZLocationManager is available under the MIT license. See the LICENSE file for more info.

## Buy Me A Beer?
[![Beerpay](https://beerpay.io/Appmazo/AMZLocationManager/badge.svg)](https://beerpay.io/Appmazo/AMZLocationManager)
