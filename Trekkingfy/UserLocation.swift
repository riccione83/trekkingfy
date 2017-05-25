//
//  UserLocation.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 24/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import MapKit

class UserLocation: NSObject, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    
    // You can access the lat and long by calling:
    // currentLocation2d.latitude, etc
    
    var currentLocation2d:CLLocationCoordinate2D?
    
    
    class var manager: UserLocation {
        return SharedUserLocation
    }
    
    override init () {
        super.init()
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 50
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        self.currentLocation2d = manager.location?.coordinate
        
    }
}
let SharedUserLocation = UserLocation()
