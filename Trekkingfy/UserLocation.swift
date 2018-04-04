//
//  LocationManager.swift
//  GooglePlacesSwift
//
//  Created by Riccardo Rizzo on 13/03/18.
//  Copyright © 2018 Riccardo Rizzo. All rights reserved.
//

import Foundation
import CoreLocation

// LocationService Class
// Singleton Class
// Used to get the user location
//

protocol LocationManagerDelegate {
    func tracingLocation(_ currentLocation: CLLocation)
    func tracingLocationDidFailWithError(_ error: NSError)
    func tracingHeading(_ currentHeading: CLHeading)
}

class LocationService: NSObject, CLLocationManagerDelegate {
    
    static let sharedInstance: LocationService = {
        let instance = LocationService()
        return instance
    }()
    
    var locationManager: CLLocationManager?
    var currentLocation: CLLocation?
    var delegate: LocationManagerDelegate?
    var isValid = true
    
    override init() {
        super.init()
        
        self.locationManager = CLLocationManager()
        guard let locationManager = self.locationManager else {
            return
        }
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
           // locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
        }
        
        locationManager.desiredAccuracy =  kCLLocationAccuracyBest // The accuracy
        //locationManager.distanceFilter = 100 // The minimum distance (measured in meters) if needed
        locationManager.delegate = self
        self.startUpdatingLocation()
    }
    
    func releaseDelegate() {
        //self.locationManager?.delegate = self
       // locationManager?.delegate = self
    }
    
    func startUpdatingHeading() {
        self.locationManager?.startUpdatingHeading()
    }
    
    func stopUpdatingHeading() {
        self.locationManager?.stopUpdatingHeading()
    }
    
    func startUpdatingLocation() {
        self.locationManager?.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        self.locationManager?.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    
        updateHeading(newHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else {
            return
        }
        currentLocation = location
        
        if !self.isValid {           //something has occurred. Set this LocationManager as invalid
            self.isValid = true
        }
        
        updateLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        updateLocationDidFailWithError(error as NSError)
    }
    
    fileprivate func updateHeading(_ currentHeading: CLHeading){
        
        guard let delegate = self.delegate else {
            return
        }
        delegate.tracingHeading(currentHeading)
    }
    
    
    fileprivate func updateLocation(_ currentLocation: CLLocation){
        
        guard let delegate = self.delegate else {
            return
        }
        delegate.tracingLocation(currentLocation)
    }
    
    fileprivate func updateLocationDidFailWithError(_ error: NSError) {
        
        guard let delegate = self.delegate else {
            return
        }
        
        if self.isValid {           //something has occurred. Set this LocationManager as invalid
            self.isValid = false
        }
        
        delegate.tracingLocationDidFailWithError(error)
    }
}
