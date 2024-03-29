//
//  SOSModeViewController.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 24/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit
import MapKit
import CoreMotion
import AVFoundation

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
}
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

class SOSModeViewController: UIViewController, LocationManagerDelegate {//CLLocationManagerDelegate {
    
    @IBOutlet var lblDistance: UILabel!
    @IBOutlet var lblGPSPosition: UILabel!
    @IBOutlet var btnSOS: UIButton!
    @IBOutlet var btnSound: UIButton!
    @IBOutlet var btnLight: UIButton!
    @IBOutlet var imgArrow: UIImageView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var navigationBarSos: UINavigationBar!
    
    // let locationManager = CLLocationManager()
    var endPoint: Point? = nil
    var pointDescription:String? = "End".localized
    var degrees = 0.0
    var currentHeading = CLHeading()
    var endOfRoute = false
    var userLocation: CLLocationCoordinate2D!
    
    private var SOSBlinkMode = false
    private var FlashMode = false
    private var SoundMode = false
    
    var player: AVAudioPlayer?
    
    /// Short signal duration (LED on)
    private static let shortInterval = 0.2
    /// Long signal duration (LED on)
    private static let longInterval = 0.4
    /// Pause between signals (LED off)
    private static let pauseInterval = 0.2
    /// Pause between the whole SOS sequences (LED off)
    private static let sequencePauseInterval = 2.0
    
    private let sequenceIntervals = [
        shortInterval, pauseInterval, shortInterval, pauseInterval, shortInterval, pauseInterval,
        longInterval, pauseInterval, longInterval, pauseInterval, longInterval, pauseInterval,
        shortInterval, pauseInterval, shortInterval, pauseInterval, shortInterval, sequencePauseInterval
    ]
    
    /// Current index in the SOS `sequence`
    private var index: Int = 0
    
    /// Non repeatable timer, because time interval varies
    private weak var timer: Timer?
    private weak var soundTimer: Timer?
    
    @objc private func soundTimerTick() {
        playSound()
    }
    
    
    @IBAction func shareButtonClick(_ sender: Any) {
        
        if let finalPoint = endPoint {
            
            let point = CLLocationCoordinate2D(latitude: finalPoint.lat, longitude: finalPoint.lon)
            
            let vCardURL = VCard.vCardURL(from: point, with: "My Position")
            
            // set up activity view controller
            let pointToShare = [ vCardURL ]
            let activityViewController = UIActivityViewController(activityItems: pointToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            
            // exclude some activity types from the list (optional)
            // activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
            
            // present the view controller
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    
    func stopSound() {
        if((player) != nil) {
            player?.stop()
        }
        soundTimer?.invalidate()
    }
    
    func playSound() {
        guard let url = Bundle.main.url(forResource: "pol", withExtension: "wav") else {
            print("error")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    private func turnFlashlight(on: Bool) {
        
        if let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch {
            do {
                try device.lockForConfiguration()
                if(on) {
                    device.torchMode = .on
                    try device.setTorchModeOn(level: 1.0)
                    
                }
                else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                print("error")
            }
        }
        
    }
    
    private func scheduleTimer() {
        
        timer = Timer.scheduledTimer(timeInterval: sequenceIntervals[index], target: self, selector: #selector(self.timerTick), userInfo: nil, repeats: false)
    }
    
    @objc private func timerTick() {
        // Increase sequence index, at the end?
        index = index + 1
        if index == sequenceIntervals.count {
            // Start from the beginning
            index = 0
        }
        // Alternate flashlight status based on current index
        // index % 2 == 0 -> is index even number? 0, 2, 4, 6, ...
        turnFlashlight(on: index % 2 == 0)
        scheduleTimer()
    }
    
    func startFlashSOSMode() {
        index = 0
        turnFlashlight(on: true)
        scheduleTimer()
    }
    
    func stopFlashSOSMode() {
        timer?.invalidate()
        turnFlashlight(on: false)
    }
    
    @IBAction func btnReturn(_ sender: Any) {
        LocationService.sharedInstance.stopUpdatingLocation()
        LocationService.sharedInstance.stopUpdatingHeading()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnLightClicked(_ sender: Any) {
        
        FlashMode = !FlashMode
        turnFlashlight(on: FlashMode)
        if(!FlashMode) {
            btnLight.setTitle("Light ON".localized, for: UIControlState.normal)
        }
        else {
            btnLight.setTitle("Light OFF".localized, for: UIControlState.normal)
        }
    }
    
    @IBAction func btnSoundClicked(_ sender: Any) {
        
        if(!SoundMode) {
            soundTimer = Timer.scheduledTimer(timeInterval:  2.0, target: self, selector: #selector(self.soundTimerTick), userInfo: nil, repeats: true)
            
            btnSound.setTitle("Sound OFF".localized, for: UIControlState.normal)
        }
        else {
            stopSound()
            btnSound.setTitle("Sound ON".localized, for: UIControlState.normal)
        }
        SoundMode = !SoundMode
    }
    
    
    @IBAction func btnSOSClicked(_ sender: Any) {
        
        if(!SOSBlinkMode) {
            SOSBlinkMode = true
            startFlashSOSMode()
            btnSOS.setTitle("SOS Light OFF".localized, for: UIControlState.normal)
        }
        else {
            SOSBlinkMode = false
            stopFlashSOSMode()
            btnSOS.setTitle("SOS Light ON".localized, for: UIControlState.normal)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBarSos.topItem?.title = "SOS Mode".localized
        // Do any additional setup after loading the view.
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        
        let endP:CLLocation = CLLocation(latitude: endPoint!.lat, longitude: endPoint!.lon)
        setPointOnMap(start_point: endP)
        
        let region = MKCoordinateRegionMakeWithDistance(endP.coordinate, 100, 100)
        mapView.setRegion(region, animated: true)
        
        LocationService.sharedInstance.delegate = self
        LocationService.sharedInstance.startUpdatingLocation()
        LocationService.sharedInstance.startUpdatingHeading()
    }
    
    
    func calculateUserAngle(current: CLLocationCoordinate2D) {
        
        var x:Double = 0, y:Double = 0 , deg:Double = 0, delLon:Double = 0;
        delLon = endPoint!.lon - current.longitude;
        y = sin(delLon) * cos(endPoint!.lat);
        x = cos(current.latitude) * sin(endPoint!.lat) - sin(current.latitude) * cos(endPoint!.lat) * cos(delLon);
        
        deg = atan2(y, x).radiansToDegrees;
        
        if(deg<0){
            deg = -deg;
        } else {
            deg = 360 - deg;
        }
        degrees = deg;
    }
    
    func setLatLonForDistanceAndAngle(userLocation: CLLocation) -> Double
    {
        let lat1 = userLocation.coordinate.latitude.degreesToRadians
        let lon1 = userLocation.coordinate.longitude.degreesToRadians
        
        let lat2 = endPoint?.lat.degreesToRadians
        let lon2 = endPoint?.lon.degreesToRadians
        let dLon = lon2! - lon1
        
        let y = sin(dLon) * cos(lat2!)
        let x = cos(lat1) * sin(lat2!) - sin(lat1) * cos(lat2!) * cos(dLon)
        
        var radiansBearing = atan2(y, x);
        if(radiansBearing < 0.0) {
            radiansBearing += 2*Double.pi;
        }
        return radiansBearing
    }
    
    func tracingHeading(_ currentHeading: CLHeading) {
        // Use the true heading if it is valid.
        let direction = -currentHeading.trueHeading;
        let rotateAng = CGFloat((direction * .pi / 180) + degrees)
        
        if (!endOfRoute) {
            imgArrow.transform = CGAffineTransform(rotationAngle: rotateAng)
        }
        
        mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
    }
    
    
    func tracingLocationDidFailWithError(_ error: NSError) {
        
    }
    
    func tracingLocation(_ currentLocation: CLLocation) {
        
        degrees = setLatLonForDistanceAndAngle(userLocation: currentLocation)
        print("Degrees: \(degrees)")
        let coordinate₀ = CLLocation(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
        let coordinate₁ = CLLocation(latitude: endPoint!.lat, longitude: endPoint!.lon)
        
        let distanceInMeters = coordinate₀.distance(from: coordinate₁) // result is in meters
        
        if(distanceInMeters < 1000) {
            lblDistance.text = "Distance:".localized + " \(distanceInMeters.roundTo(places: 0)) mt"
        }
        else {
            lblDistance.text = "Distance".localized +  " \((distanceInMeters/1000).roundTo(places: 2)) km"
        }
        
        lblGPSPosition.text = "GPS: \(currentLocation.coordinate.latitude.roundTo(places: 5)) - \(currentLocation.coordinate.longitude.roundTo(places: 5))"
        
        if distanceInMeters <= CLLocationDistance(5.0) {
            if !endOfRoute {
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                let animation = CATransition()
                animation.duration = 0.3
                animation.type = kCATransitionFade
                imgArrow.layer.add(animation, forKey: "ImageFade")
                imgArrow.image = UIImage(named: "ok.png")
                imgArrow.contentMode = .scaleAspectFill
                imgArrow.transform = CGAffineTransform(rotationAngle: 0.0)
                endOfRoute = true
            }
        }
        else
        {
            imgArrow.image = UIImage(named: "arrow.png")
            imgArrow.contentMode = .scaleToFill
            endOfRoute = false
        }
    }
    
    func setPointOnMap(start_point:CLLocation) {
        
        let point = MKPointAnnotation()
        point.coordinate = start_point.coordinate
        point.title = pointDescription
        mapView.addAnnotation(point)
    }
    
}


extension SOSModeViewController: MKMapViewDelegate {
    
    /*  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
     let latitudineDelta = Float(mapView.region.span.latitudeDelta)
     }
     */
}

