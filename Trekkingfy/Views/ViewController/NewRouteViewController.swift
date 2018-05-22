//
//  NewRouteViewController.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 20/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit
import ScrollableGraphView
import MapKit
import RealmSwift

protocol RouteSaveExtension {
    func saveNewRoute(route:Route)
}

class NewRouteViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, PhotoShootDelegate, LocationManagerDelegate {
    
    @IBOutlet var graphView: UIView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var imagePositionGrid: UICollectionView!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var barGraphHeightConstraint: NSLayoutConstraint!
    @IBOutlet var fingetTipAnimationView: FingerAnimationView!
    
    
    var mainView:RouteSaveExtension? = nil
    let updateLocationInterval = 5  //5 secs
    var timerUpdateLocation:Timer? = nil
    var currentRoute:Route?
    var altitudeBarLoaded = false
    var oldPositions:[CLLocationCoordinate2D]? = []
    var mapWasCentered = false
    var graphBarView = ScrollableGraphView()
    var graphConstraints = [NSLayoutConstraint]()
    var label = UILabel()
    var labelConstraints = [NSLayoutConstraint]()
    var inStop = false
    var GPSFixed = false
    var gpsFixCount = 0
    var kDelayBarBounce = 0.1
    var lblGood = false
    var lblNotGood = false
    var lblBad = false
    var lastImagePositionGridHeight:CGFloat = 0.0
    var isFingerShowed = false
    var isAltitudeBarHidden = false
    
    @IBAction func showGraphTapped() {
        
        guard lastImagePositionGridHeight != 0.0 else {return}
        
        isAltitudeBarHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.imagePositionGrid.frame = CGRect(x: self.imagePositionGrid.frame.origin.x, y: self.imagePositionGrid.frame.origin.y, width: self.imagePositionGrid.frame.width, height: self.lastImagePositionGridHeight)
            self.label.alpha = 1.0
            self.graphView.alpha = 1.0
        },
                       completion: {(complete) in
                        self.lastImagePositionGridHeight = 0.0
        })
    }
    
    @IBAction func swipeDownGraph() {
        
        hideGraph(completition: {_ in })
    }
    
    
    func hideGraph(completition:@escaping (_ success:Bool) -> ()) {
        
        guard lastImagePositionGridHeight == 0.0 else { return }
        
        isAltitudeBarHidden = true
        
        lastImagePositionGridHeight = self.imagePositionGrid.frame.height
        
        UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: [], animations: {
            
            self.imagePositionGrid.frame = CGRect(x: self.imagePositionGrid.frame.origin.x, y: self.imagePositionGrid.frame.origin.y, width: self.imagePositionGrid.frame.width, height: self.imagePositionGrid.frame.height + self.graphView.frame.height)
            self.label.alpha = 0.0
            self.graphView.alpha = 0.0
            
        }) { (success) in
            
            completition(true)
            
        }
    }
    
    @IBAction func graphTapped() {
        
        hideGraph(completition: {_ in })
    }
    
    @IBAction func returnToMainAndSave(_ sender: Any) {
        
        inStop = true
        self.timerUpdateLocation?.invalidate()
        self.timerUpdateLocation = nil
        UIApplication.shared.isIdleTimerDisabled = false
        LocationService.sharedInstance.stopUpdatingLocation()
        
        if(currentRoute?.ID == -1) {
            self.mapView.showsUserLocation = false
            
            let alert = UIAlertController(title: "Save Route?".localized, message: "Do you want to save this route?".localized, preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "Yes".localized, style: .default, handler: { (UIAlertAction) in
                
                if(self.mainView != nil) {
                    let alertController = UIAlertController(title: "Add New Name".localized, message: "", preferredStyle: .alert)
                    
                    alertController.addAction(UIKit.UIAlertAction(title: "Save".localized, style: .default, handler: { (UIAlertAction) in
                        let routeName = alertController.textFields![0] as UITextField
                        if let name = routeName.text {
                            if name == "" {
                                self.currentRoute?.Name = "Route".localized
                            }
                            else {
                                self.currentRoute?.Name = name
                            }
                        }
                        else {
                            self.currentRoute?.Name = "Route".localized
                        }
                        self.mainView?.saveNewRoute(route: self.currentRoute!)
                        self.dismiss(animated: true) { }
                    }))
                    
                    alertController.addTextField { (textField : UITextField!) -> Void in
                        textField.placeholder = "Route".localized
                        textField.autocapitalizationType = UITextAutocapitalizationType.sentences
                    }
                    
                    self.present(alertController,animated: true, completion: nil)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "No".localized, style: .default, handler: { (UIAlertAction) in
                
                self.currentRoute = nil
                self.mapView.delegate = nil
                self.oldPositions = nil
                self.graphBarView.removeFromSuperview()
                
                LocationService.sharedInstance.stopUpdatingLocation()
                LocationService.sharedInstance.delegate = nil
                LocationService.sharedInstance.releaseDelegate()
                
                self.imagePositionGrid.delegate = nil
                self.graphView = nil
                self.dismiss(animated: false, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { (UIAlertAction) in
                LocationService.sharedInstance.delegate = self
                LocationService.sharedInstance.startUpdatingLocation()
                self.mapView.showsUserLocation = true
                self.inStop = false
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            self.dismiss(animated: false) { }
        }
        
        
    }
    
    func compressImage(image:UIImage) -> NSData {
        // Reducing file size to a 10th
        
        var actualHeight : CGFloat = image.size.height
        var actualWidth : CGFloat = image.size.width
        let maxHeight : CGFloat = 1136.0
        let maxWidth : CGFloat = 640.0
        var imgRatio : CGFloat = actualWidth/actualHeight
        let maxRatio : CGFloat = maxWidth/maxHeight
        var compressionQuality : CGFloat = 0.5
        
        if (actualHeight > maxHeight || actualWidth > maxWidth){
            if(imgRatio < maxRatio){
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight;
                actualWidth = imgRatio * actualWidth;
                actualHeight = maxHeight;
            }
            else if(imgRatio > maxRatio){
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth;
                actualHeight = imgRatio * actualHeight;
                actualWidth = maxWidth;
            }
            else{
                actualHeight = maxHeight;
                actualWidth = maxWidth;
                compressionQuality = 1;
            }
        }
        let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
        
        UIGraphicsBeginImageContext(rect.size);
        image.draw(in: rect)
        let img = UIGraphicsGetImageFromCurrentImageContext();
        let imageData = UIImageJPEGRepresentation(img!, compressionQuality);
        UIGraphicsEndImageContext();
        
        return imageData! as NSData
    }
    
    func returnWithPhotoError() {
        inStop = false
    }
    
    func setPhoto(image:UIImage, id:Int, note:String) {
        
        if currentRoute?.ID == -1 {
            
            guard let latitude = LocationService.sharedInstance.currentLocation?.coordinate.latitude else { return }
            
            let pos = DataPoint(lat: latitude, lon: LocationService.sharedInstance.currentLocation!.coordinate.longitude)
            
            if(id == -1) {              //new point
                
                let compressedImage = compressImage(image: image)
                // let compressed_image = UIImage(data: compressedImage as Data)
                
                currentRoute?.Images.append(DataImage(data: compressedImage))
                currentRoute?.ImageDescriptions.append(DataText(text: note))
                currentRoute?.ImagesPositions.append(pos)
                
                DispatchQueue.main.async {
                    let pointCoord = CLLocation(latitude: pos.lat, longitude: pos.lon)
                    self.addNewPoint(start_point: pointCoord,description: note)
                }
                
            }
            else {
                if(id <= (currentRoute?.Images.count)!) {
                    if(currentRoute?.Images[id].data.length != 0) {  //Check if is nil
                        currentRoute?.Images[id] = DataImage(data: UIImageJPEGRepresentation(image, 1.0)! as NSData)
                        currentRoute?.ImageDescriptions[id] = DataText(text: note)
                        
                        currentRoute?.ImagesPositions[id] = pos
                    }
                }
            }
            //imagePositionGrid.reloadData()
            imagePositionGrid.performBatchUpdates({
                imagePositionGrid.insertItems(at: [IndexPath(row: currentRoute!.Images.count - 1 , section: 0)])
                if self.isAltitudeBarHidden {
                    self.imagePositionGrid.frame = CGRect(x: self.imagePositionGrid.frame.origin.x, y: self.imagePositionGrid.frame.origin.y, width: self.imagePositionGrid.frame.width, height: self.imagePositionGrid.frame.height + self.graphView.frame.height)
                }
            }) { (success) in
                if self.isAltitudeBarHidden {
                               self.imagePositionGrid.frame = CGRect(x: self.imagePositionGrid.frame.origin.x, y: self.imagePositionGrid.frame.origin.y, width: self.imagePositionGrid.frame.width, height: self.imagePositionGrid.frame.height + self.graphView.frame.height)
                }
            }
            
            mapView.showsUserLocation = true
            inStop = false
        }
    }
    
    @IBAction func btnSOSClicked(_ sender: Any) {     
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SOSModeViewController") as! SOSModeViewController
        
        //Check here - FIX
        if(currentRoute?.Positions.count == 0) {
            currentRoute?.Positions.append(DataPoint(lat: (LocationService.sharedInstance.currentLocation?.coordinate.latitude)!, lon: (LocationService.sharedInstance.currentLocation?.coordinate.longitude)!))
        }
        
        vc.endPoint = currentRoute?.Positions.first?.toPoint()
        
        vc.pointDescription = "End Point".localized
        LocationService.sharedInstance.releaseDelegate()
        self.present(vc, animated: false, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if(!inStop) {
            LocationService.sharedInstance.delegate = self
            LocationService.sharedInstance.startUpdatingLocation()
        }
    }
    
    
    private func updateAltimeterGraph() {
        
        if isAltitudeBarHidden { return }
        
        let d = currentRoute?.Altitudes.map( { $0.altitude })
        var numberOfPoint = 5
        let orientation = UIDevice.current.orientation
        
        if(orientation == UIDeviceOrientation.landscapeLeft || orientation == UIDeviceOrientation.landscapeRight) { // || orientation == UIDeviceOrientation.faceUp) {
            numberOfPoint = 10
        }
        
        let data:[Double] = Array(d!.suffix(numberOfPoint))
        if((currentRoute?.Altitudes.count)! > 0) {
            graphBarView.animationDuration = kDelayBarBounce
            graphBarView.set(data: data, withLabels: self.generateSequentialLabels(data.count, texts:data))
        }
        
        if currentRoute?.ID == -1 && data.count >= numberOfPoint && !isFingerShowed {
            isFingerShowed = true
            hideGraph(completition: {_ in
                self.fingetTipAnimationView.isHidden = false
                UIView.animateKeyframes(withDuration: 2.0, delay: 1.0, options: [.repeat, .autoreverse], animations: {
                    UIView.setAnimationRepeatCount(2)
                    self.fingetTipAnimationView.center.y += 150
                }) { (success) in
                    UIView.animate(withDuration: 0.5, animations: {
                        self.fingetTipAnimationView.center.y -= 150
                        self.fingetTipAnimationView.alpha = 0.0
                    }, completion: { (success) in
                        self.fingetTipAnimationView.isHidden = true
                    })
                }
            })
        }
    }
    
    private func setupUI() {
        
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        navigationBar.topItem?.title = "Route".localized
        
        graphBarView = ScrollableGraphView(frame: self.graphView.frame)
        graphBarView = createDarkGraph(self.graphView.frame)
        
        if(currentRoute?.ID == -1) {
            
            LocationService.sharedInstance.delegate = self
            LocationService.sharedInstance.startUpdatingLocation()
            
            /* locationManager.delegate = self
             locationManager.distanceFilter = CLLocationDistance(exactly: 5)!  //kCLDistanceFilterNone
             locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
             locationManager.requestAlwaysAuthorization()
             locationManager.allowsBackgroundLocationUpdates = true
             locationManager.startUpdatingLocation()
             */
            
            
            updateAltimeterGraph()
            
            if let altitude = LocationService.sharedInstance.currentLocation?.altitude {
                
                let data: [Double] = [altitude]
                
                graphBarView.set(data: data, withLabels: self.generateSequentialLabels(1, texts: data))
            }
        }
        else {
            inStop = true
            kDelayBarBounce = 0.8
            
            let d = currentRoute?.Altitudes.map( { $0.altitude })
            
            let data:[Double] = Array(d!) //.suffix(5))
            
            if((currentRoute?.Altitudes.count)! > 0) {
                graphBarView.set(data: data, withLabels: self.generateSequentialLabels(data.count, texts:data))
            }
            
            var loc:CLLocation = CLLocation()
            for p in (currentRoute?.Positions)! {
                loc = CLLocation(latitude: p.lat, longitude: p.lon)
                updateLines(newPoint: loc)
            }
            
            if let routeCnt = currentRoute?.Positions.count {
                
                if routeCnt >= 2 {
                    let startPoint = CLLocation(latitude: (currentRoute?.Positions.first?.lat)!, longitude: (currentRoute?.Positions.first?.lon)!)
                    setInitialPoint(start_point: startPoint)
                    
                    let finalPoint = CLLocation(latitude: (currentRoute?.Positions.last?.lat)!, longitude: (currentRoute?.Positions.last?.lon)!)
                    setFinalPoint(start_point: finalPoint)
                    
                    var cnt = 0
                    for point in (currentRoute?.ImagesPositions)! {
                        let coord = CLLocation(latitude: point.lat, longitude: point.lon)
                        addNewPoint(start_point: coord, description: (currentRoute?.ImageDescriptions[cnt].text)!)
                        cnt = cnt + 1
                    }
                }
            }
            
            let region = MKCoordinateRegionMakeWithDistance(loc.coordinate, 100, 100)
            mapView.setRegion(region, animated: true)
            
        }
        
        self.graphView.addSubview(graphBarView)
        
        setupConstraints()
        altitudeBarLoaded = true
    }
    
    //func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    func tracingLocationDidFailWithError(_ error: NSError) {
    }
    
    func tracingHeading(_ currentHeading: CLHeading) {
    }
    
    func tracingLocation(_ currentLocation: CLLocation) {
        print("Got new location")
        
        if(!inStop) {
            mapView.showsUserLocation = true
            if(!mapWasCentered) {
                mapWasCentered = true
                let region = MKCoordinateRegionMakeWithDistance(currentLocation.coordinate, 0.01, 0.01)
                mapView.setRegion(region, animated: true)
            }
            
            if(GPSFixed) {
                let pos = DataPoint(lat: currentLocation.coordinate.latitude, lon: currentLocation.coordinate.longitude)
                currentRoute?.Positions.append(pos)
                currentRoute?.Altitudes.append(DataAltitude(altitude: currentLocation.altitude))
                updateLines(newPoint: currentLocation)
            }
            
            if((currentRoute?.Positions.count)!>0) {
                mapView.setCenter(currentLocation.coordinate, animated: true)
            }
            
            
            if(altitudeBarLoaded) { // && GPSFixed) {
                updateAltimeterGraph()
            }
            
            if (!GPSFixed) {
                gpsFixCount = gpsFixCount + 1
                if(gpsFixCount >= 3) {
                    GPSFixed = true
                    // locationManager.distanceFilter = CLLocationDistance(exactly: 20)!  //kCLDistanceFilterNone
                }
            }
            
            if !isAltitudeBarHidden {
                if(currentLocation.horizontalAccuracy <= 10) {
                    if(!lblGood) {
                        addLabel(withText: "GPS: Good".localized, value: 1.0)
                        lblGood = true
                        lblNotGood = false
                        lblBad = false
                        GPSFixed = true
                        //locationManager.distanceFilter = CLLocationDistance(exactly: 20)!  //kCLDistanceFilterNone
                        // LocationService.sharedInstance.locationManager.distanceFilter = CLLocationDistance(exactly: 20)!  //kCLDistanceFilterNone
                    }
                }
                else if(currentLocation.horizontalAccuracy <= 170) {
                    if( !lblNotGood) {
                        addLabel(withText: "GPS: Not Good".localized, value: 0.5)
                        lblGood = false
                        lblNotGood = true
                        lblBad = false
                    }
                }
                else if (!lblBad){
                    addLabel(withText: "GPS: Bad".localized, value: 0.0)
                    lblGood = false
                    lblNotGood = false
                    lblBad = true
                }
            }
        }
    }
    
    
    func addNewPoint(start_point:CLLocation, description:String) {
        
        let point = MKPointAnnotation()
        point.coordinate = start_point.coordinate
        point.title = description
        mapView.addAnnotation(point)
        //   recreateLines(newPoint: start_point)
    }
    
    func setInitialPoint(start_point:CLLocation) {
        
        let point = MKPointAnnotation()
        point.coordinate = start_point.coordinate
        point.title = "Start".localized
        mapView.addAnnotation(point)
        //  recreateLines(newPoint: start_point)
    }
    
    func setFinalPoint(start_point:CLLocation) {
        
        let point = MKPointAnnotation()
        point.coordinate = start_point.coordinate
        point.title = "Stop".localized
        mapView.addAnnotation(point)
        //  recreateLines(newPoint: start_point)
        mapView.selectAnnotation(point, animated: true)
    }
    
    func recreateLines(newPoint: CLLocation) {
        
        oldPositions!.append(newPoint.coordinate)
        let route = MKPolyline(coordinates: oldPositions!, count: oldPositions!.count)
        mapView.add(route)
    }
    
    func updateLines(newPoint: CLLocation) {
        
        let route = MKPolyline(coordinates: (currentRoute?.Positions_in_CLLocationCoordinate2D)!, count: (currentRoute?.Positions.count)!)
        // mapView.remo
        mapView.add(route)
    }
    
    private func addLabel(withText text: String, value: Float) {
        
        label.removeFromSuperview()
        label = createLabel(withText: text, value: value)
        label.isUserInteractionEnabled = true
        
        let rightConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.graphView, attribute: NSLayoutAttribute.right, multiplier: 1, constant: -20)
        
        let topConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.graphView, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 20)
        
        let heightConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 40)
        let widthConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: label.frame.width * 1.5)
        
        let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(didTap))
        label.addGestureRecognizer(tapGestureRecogniser)
        
        self.view.insertSubview(label, aboveSubview: graphView)
        self.view.addConstraints([rightConstraint, topConstraint, heightConstraint, widthConstraint])
    }
    
    func didTap(_ gesture: UITapGestureRecognizer) {
        
    }
    
    private func createLabel(withText text: String, value: Float) -> UILabel {
        let label = UILabel()
        
        if(value > 0.5) {
            label.backgroundColor = UIColor.green.withAlphaComponent(0.5)
        }
        else if(value == 0.5) {
            label.backgroundColor = UIColor.yellow.withAlphaComponent(0.5)
        }
        else {
            label.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        }
        
        label.text = text
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont.boldSystemFont(ofSize: 14)
        
        label.layer.cornerRadius = 2
        label.clipsToBounds = true
        
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        
        return label
    }
    
    private func setupConstraints() {
        
        self.graphBarView.translatesAutoresizingMaskIntoConstraints = false
        graphConstraints.removeAll()
        
        let topConstraint = NSLayoutConstraint(item: self.graphBarView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.graphView, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: self.graphBarView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.graphView, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.graphBarView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.graphView, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        let leftConstraint = NSLayoutConstraint(item: self.graphBarView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.graphView, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
        
        //let heightConstraint = NSLayoutConstraint(item: self.graphView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
        
        graphConstraints.append(topConstraint)
        graphConstraints.append(bottomConstraint)
        graphConstraints.append(leftConstraint)
        graphConstraints.append(rightConstraint)
        
        //graphConstraints.append(heightConstraint)
        
        self.graphView.addConstraints(graphConstraints)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        oldPositions = []
        mapWasCentered = false
        
        
        
        // Do any additional setup after loading the view.
        UIApplication.shared.isIdleTimerDisabled = true
        
        if(currentRoute == nil) {
            currentRoute = Route()
        }
        
        setupUI()
    }
    
    private func generateSequentialLabels(_ numberOfItems: Int, texts: [Double]) -> [String] {
        var labels = [String]()
        
        for i in 0 ..< numberOfItems {
            labels.append("mt: \(texts[i].roundTo(places: 0))")
        }
        
        return labels
    }
    
    fileprivate func createDarkGraph(_ frame: CGRect) -> ScrollableGraphView {
        let graphView = ScrollableGraphView(frame: frame)
        
        graphView.backgroundFillColor = imagePositionGrid.backgroundColor!  //UIColor.colorFromHex(hexString: "#333333")
        //self.view.backgroundColor = imagePositionGrid.backgroundColor!
        
        graphView.lineWidth = 1
        graphView.lineColor = UIColor.colorFromHex(hexString: "#777777")
        graphView.lineStyle = ScrollableGraphViewLineStyle.smooth
        
        graphView.shouldFill = true
        graphView.fillType = ScrollableGraphViewFillType.gradient
        graphView.fillColor = imagePositionGrid.backgroundColor!//UIColor.colorFromHex(hexString: "#555555")
        graphView.fillGradientType = ScrollableGraphViewGradientType.linear
        graphView.fillGradientStartColor = imagePositionGrid.backgroundColor! //UIColor.colorFromHex(hexString: "#555555")
        graphView.fillGradientEndColor = UIColor.colorFromHex(hexString: "#444444")
        
        graphView.dataPointSpacing = 80
        graphView.dataPointSize = 2
        graphView.dataPointFillColor = UIColor.white
        
        graphView.bottomMargin = 15
        
        graphView.referenceLineLabelFont = UIFont.boldSystemFont(ofSize: 8)
        graphView.referenceLineColor = UIColor.white.withAlphaComponent(0.2)
        graphView.referenceLineLabelColor = UIColor.white
        graphView.numberOfIntermediateReferenceLines = 5
        graphView.dataPointLabelColor = UIColor.white.withAlphaComponent(0.5)
        
        graphView.shouldAnimateOnStartup = true
        graphView.shouldAdaptRange = true
        graphView.adaptAnimationType = ScrollableGraphViewAnimationType.elastic
        graphView.animationDuration = 1.5
        graphView.rangeMax = 50
        graphView.shouldRangeAlwaysStartAtZero = true
        
        return graphView
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "cameraStoryboard") as? PhotoCameraViewController {
            
            //self.locationManager.stopUpdatingLocation()
            //self.mapView.showsUserLocation = false
            self.inStop = true
            
            if let count = currentRoute?.Images.count {
                if(indexPath.row == count) {
                    vc.currentID = -1
                }
                else {
                    vc.currentID = indexPath.row
                    if(!((currentRoute?.Images[indexPath.row] == nil))) {
                        vc.currentNote = currentRoute?.ImageDescriptions[indexPath.row].text
                        let image = UIImage(data: currentRoute!.Images[indexPath.row].data as Data)
                        vc.currentImage = image!
                        vc.currentLocation = currentRoute?.ImagesPositions[indexPath.row].toPoint()
                    }
                }
                
                vc.mainViewDelegate = self
                //locationManager.stopUpdatingLocation()
                //locationManager.delegate = nil
                
                let transition = CATransition()
                transition.duration = 0.5
                transition.type = kCATransitionPush
                transition.subtype = kCATransitionFromLeft  //kCATransitionFromRight
                view.window!.layer.add(transition, forKey: kCATransition)
                
                self.present(vc, animated: false, completion: nil)
            }
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if(currentRoute?.ImagesPositions == nil) {
            return 1
        }
        else {
            return currentRoute!.Images.count + 1
        }
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: POIViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "addCellIdentifier", for: indexPath) as! POIViewCell
        
        if(currentRoute != nil) {
            if(!(currentRoute?.Images.isEmpty)!) {
                if(indexPath.row < (currentRoute?.Images.count)! ) {
                    if (currentRoute?.Images[indexPath.row] != nil) {
                        
                        let data = currentRoute!.Images[indexPath.row].data as Data
                        cell.imageView.image = resizeImage(image: UIImage(data: data)!, newWidth: 100)
                        cell.lblPlus.isHidden = true
                        cell.viewText.strTitle = (self.currentRoute?.ImageDescriptions[indexPath.row].text)!
                        cell.viewText.strDescription = ""
                        cell.lblPlus.isHidden = true
                        
                        //   DispatchQueue.global(qos: .default).async {
                        //        cell.imageView.image?.getColors { colors in
                        //             cell.viewText.colorText = colors.primary
                        cell.viewText.colorText = UIColor.red
                        cell.viewText.reDraw()
                        cell.lblPlus.isHidden = true
                        //          }
                        //        }
                        
                    }
                }
                else
                {
                    cell.imageView.image = nil
                    cell.lblPlus.isHidden = false
                }
            }
        }
        
        cell.contentView.layer.cornerRadius = 2.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        return cell
    }
}


extension NewRouteViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if(overlay.isKind(of: MKPolyline.classForCoder())) {
            let aView =  MKPolylineRenderer(polyline: overlay as! MKPolyline)
            aView.fillColor = UIColor.black.withAlphaComponent(0.2)
            aView.strokeColor = UIColor.blue.withAlphaComponent(0.7)
            aView.lineWidth = 3
            return aView
        }
        else {
            return MKOverlayRenderer()
        }
    }
    
}

