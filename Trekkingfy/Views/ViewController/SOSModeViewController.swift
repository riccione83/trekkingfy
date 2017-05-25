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

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
}
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

class SOSModeViewController: UIViewController, CLLocationManagerDelegate {

    
    @IBOutlet var lblX: UILabel!
    
    @IBOutlet var lblY: UILabel!
    
    @IBOutlet var lblZ: UILabel!
    
    @IBOutlet var lblDegree: UILabel!
    
    @IBOutlet var imgArrow: UIImageView!
    
    @IBOutlet var mapView: MKMapView!
    
   // private let locationManager = AppDelegate().locationManager
    
    let locationManager = CLLocationManager()
    var endPoint: Point? = nil

    var currentHEADValue: Double? = nil
    var x:Double? = 0.0
    var y:Double? = 0.0
    var z:Double? = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mapView.delegate = self
        mapView.showsUserLocation = true
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

    func getDegrees(startPoint:Point,endPoint:Point, headX: Double) -> Double {
        
        var lat1:Double = startPoint.lat!
        let lon1:Double = startPoint.lon!
        
        var lat2:Double = endPoint.lat!
        let lon2:Double = endPoint.lon!
        
       // var dLat = Double(lat2 - lat1).degreesToRadians
        let dLon = Double(lon2 - lon1).degreesToRadians
        
        lat1 = lat1.degreesToRadians
        lat2 = lat2.degreesToRadians
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1)*cos(lat2)*cos(dLon)
        
        var brng = atan2(y, x).radiansToDegrees
        
        if(brng < 0) {
            brng = 360 - abs(brng)
        }
        
        return brng - headX
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Use the true heading if it is valid.
        let direction = -newHeading.magneticHeading / 180.0 * Double.pi
        
        let strAccuracy = "\(newHeading.headingAccuracy)"
        lblX.text = "Accuracy: \(strAccuracy)"
        lblY.text = "Direction: \(direction)"
        
        let arrowImage = UIImage(named: "Arrow-Free-Download-PNG.png")
        imgArrow.image = imageRotatedByDegrees(oldImage: arrowImage!, deg: CGFloat(direction.radiansToDegrees))
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        /*if(endPoint != nil && currentHEADValue != nil) {
            
            currentHEADValue = locations.last?.course
            let currPoint = Point(val: locations.last!.coordinate)
        

            let degree = getDegrees(startPoint: currPoint, endPoint: endPoint!, headX: currentHEADValue!)
            
            lblDegree.text = "Degree: \(degree)"
            lblX.text = "X: \(x!)"
            lblY.text = "Y: \(y!)"
            lblZ.text = "Z: \(z!)"
            
            let arrowImage = UIImage(named: "Arrow-Free-Download-PNG.png")
            
            imgArrow.image = imageRotatedByDegrees(oldImage: arrowImage!, deg: CGFloat(degree))
        }*/
    }
    
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    
    func setPointOnMap(start_point:CLLocation) {
        
        let point = MKPointAnnotation()
        point.coordinate = start_point.coordinate
        point.title = "End"
        mapView.addAnnotation(point)
        //mapView.selectAnnotation(point, animated: true)
    }
    
}


extension SOSModeViewController: MKMapViewDelegate {
    
}

