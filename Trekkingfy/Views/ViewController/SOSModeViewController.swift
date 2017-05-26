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

class SOSModeViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var lblDistance: UILabel!
    @IBOutlet var lblGPSPosition: UILabel!
    
    @IBOutlet var btnSOS: UIButton!
    @IBOutlet var btnSound: UIButton!
    @IBOutlet var btnLight: UIButton!
    @IBOutlet var imgArrow: UIImageView!
    @IBOutlet var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var endPoint: Point? = nil

    var degrees = 0.0
   /* var x:Double? = 0.0
    var y:Double? = 0.0
    var z:Double? = 0.0*/
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
        
        if let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo), device.hasTorch {
            do {
                try device.lockForConfiguration()
                if(on) {
                    device.torchMode = .on
                    try device.setTorchModeOnWithLevel(1.0)

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
    
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func btnLightClicked(_ sender: Any) {

        FlashMode = !FlashMode
        turnFlashlight(on: FlashMode)
        if(!FlashMode) {
                    btnLight.setTitle("Light ON", for: UIControlState.normal)
        }
        else {
                    btnLight.setTitle("Light OFF", for: UIControlState.normal)
        }
        
    }
    
    
    @IBAction func btnSoundClicked(_ sender: Any) {

        if(!SoundMode) {
            soundTimer = Timer.scheduledTimer(timeInterval:  2.0, target: self, selector: #selector(self.soundTimerTick), userInfo: nil, repeats: true)
            
            btnSound.setTitle("Sound OFF", for: UIControlState.normal)
        }
        else {
            stopSound()
            btnSound.setTitle("Sound ON", for: UIControlState.normal)
        }
        SoundMode = !SoundMode
    }
    
    
    @IBAction func btnSOSClicked(_ sender: Any) {
        
        if(!SOSBlinkMode) {
            SOSBlinkMode = true
            startFlashSOSMode()
            btnSOS.setTitle("SOS Light OFF", for: UIControlState.normal)
        }
        else {
            SOSBlinkMode = false
            stopFlashSOSMode()
            btnSOS.setTitle("SOS Light ON", for: UIControlState.normal)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = MKUserTrackingMode.follow
        mapView.showsCompass = true
        
        let endP:CLLocation = CLLocation(latitude: endPoint!.lat!, longitude: endPoint!.lon!)
        setPointOnMap(start_point: endP)
        
        let region = MKCoordinateRegionMakeWithDistance(endP.coordinate, 100, 100)
        mapView.setRegion(region, animated: true)
        
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
    }
    
    func calculateUserAngle(current: CLLocationCoordinate2D) -> CGFloat {
        var x = 0.0
        var y = 0.0
        var deg = 0.0
        var delLon = 0.0
    
        delLon = endPoint!.lon! - current.longitude;
        y = sin(delLon) * cos(endPoint!.lat!);
        x = cos(current.latitude) * sin(endPoint!.lat!) - sin(current.latitude) * cos(endPoint!.lat!) * cos(delLon);
        deg = (atan2(y, x)).radiansToDegrees;
    
        if(deg<0){
                deg = -deg;
        } else {
                deg = 360 - deg;
        }
        return CGFloat(deg);
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Use the true heading if it is valid.
        
        imgArrow.transform = CGAffineTransform(rotationAngle: CGFloat((degrees-newHeading.trueHeading) * M_PI / 180))
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let here = locations.last?.coordinate
        degrees = Double(self.calculateUserAngle(current: here!))
    }
    
    func setPointOnMap(start_point:CLLocation) {
        
        let point = MKPointAnnotation()
        point.coordinate = start_point.coordinate
        point.title = "End"
        mapView.addAnnotation(point)
    }
    
}


extension SOSModeViewController: MKMapViewDelegate {
    
}

