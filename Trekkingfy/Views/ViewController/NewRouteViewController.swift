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

class NewRouteViewController: UIViewController, CLLocationManagerDelegate,UICollectionViewDelegate, UICollectionViewDataSource, PhotoShootDelegate {
    
    @IBOutlet var graphView: UIView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var imagePositionGrid: UICollectionView!
    @IBOutlet var navigationBar: UINavigationBar!
    
    var mainView:RouteSaveExtension? = nil
    let updateLocationInterval = 5  //5 secs
    var timerUpdateLocation:Timer? = nil
    
    var currentRoute:Route?
    
    var altitudeBarLoaded = false
    var oldPositions:[CLLocationCoordinate2D] = []
    var locationManager = CLLocationManager()
    var mapWasCentered = false
    var graphBarView = ScrollableGraphView()
    var graphConstraints = [NSLayoutConstraint]()
    var label = UILabel()
    var labelConstraints = [NSLayoutConstraint]()
    var inStop = false
    
    @IBAction func returnToMainAndSave(_ sender: Any) {
        
        inStop = true
        
        self.locationManager.stopUpdatingLocation()
        self.timerUpdateLocation?.invalidate()
        self.timerUpdateLocation = nil
        UIApplication.shared.isIdleTimerDisabled = false
        
        if(currentRoute?.ID == -1) {
            
            let alert = UIAlertController(title: "Save Route?".localized, message: "Do you want to save this route?".localized, preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "Yes".localized, style: .default, handler: { (UIAlertAction) in
                
                if(self.mainView != nil) {
                    self.mainView?.saveNewRoute(route: self.currentRoute!)
                }
                
                self.dismiss(animated: true) { }
                
            }))
            
            alert.addAction(UIAlertAction(title: "No".localized, style: .cancel, handler: { (UIAlertAction) in
                
                self.dismiss(animated: true) { }
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            self.dismiss(animated: true) { }
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
    
    
    func setPhoto(image:UIImage, id:Int, note:String) {
        
        let pos = DataPoint(lat: locationManager.location!.coordinate.latitude, lon: locationManager.location!.coordinate.longitude)
        
        if(id == -1) {              //new point
            
            let compressedImage = compressImage(image: image)
            // let compressed_image = UIImage(data: compressedImage as Data)
            
            currentRoute?.Images.append(DataImage(data: compressedImage))
            currentRoute?.ImageDescriptions.append(DataText(text: note))
            currentRoute?.ImagesPositions.append(pos)
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
        imagePositionGrid.reloadData()
    }
    
    @IBAction func btnSOSClicked(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SOSModeViewController") as! SOSModeViewController
        vc.endPoint = currentRoute?.Positions.first?.toPoint()
        vc.pointDescription = "End Point".localized
        locationManager.stopUpdatingLocation()
        self.present(vc, animated: false, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Do any additional setup after loading the view.
        UIApplication.shared.isIdleTimerDisabled = true
        
        if(currentRoute == nil) {
            currentRoute = Route()
        }
        
        setupUI()
        
     //   timerUpdateLocation = Timer.scheduledTimer(timeInterval: TimeInterval(updateLocationInterval), target: self, selector: #selector(self.updateNewLocationTimer), userInfo: nil, repeats: true)
        
    }
    
    func updateNewLocationTimer() {
        
        if(!inStop) {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.startUpdatingLocation()
        }
    }
    
    private func updateAltimeterGraph() {
        
        let d = currentRoute?.Altitudes.map( { $0.altitude })
        
        var numberOfPoint = 5
        
        let orientation = UIDevice.current.orientation
        
        if(orientation == UIDeviceOrientation.landscapeLeft || orientation == UIDeviceOrientation.landscapeRight) {
            numberOfPoint = 10
        }
        
        let data:[Double] = Array(d!.suffix(numberOfPoint))
        if((currentRoute?.Altitudes.count)! > 0) {
            graphBarView.set(data: data, withLabels: self.generateSequentialLabels(data.count, texts:data))
        }
        
    }
    
    private func setupUI() {
        
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        navigationBar.topItem?.title = "Route".localized
        
        graphBarView = ScrollableGraphView(frame: self.graphView.frame)
        graphBarView = createDarkGraph(self.graphView.frame)
        
        if(currentRoute?.ID == -1) {
            
            let data: [Double] = [0]
            
            graphBarView.set(data: data, withLabels: self.generateSequentialLabels(1, texts: data))
            
            locationManager.delegate = self
            locationManager.distanceFilter = CLLocationDistance(exactly: 10)!  //kCLDistanceFilterNone
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.requestAlwaysAuthorization()
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.startUpdatingLocation()
        }
        else {
            inStop = true
            let d = currentRoute?.Altitudes.map( { $0.altitude })
            
            let data:[Double] = Array(d!.suffix(5))
            
            if((currentRoute?.Altitudes.count)! > 0) {
                graphBarView.set(data: data, withLabels: self.generateSequentialLabels(data.count, texts:data))
            }
            
            
            var loc:CLLocation = CLLocation()
            for p in (currentRoute?.Positions)! {
                loc = CLLocation(latitude: p.lat, longitude: p.lon)
                updateLines(newPoint: loc)
            }
            
            
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
            
            let region = MKCoordinateRegionMakeWithDistance(loc.coordinate, 100, 100)
            mapView.setRegion(region, animated: true)
            
        }
        
        self.graphView.addSubview(graphBarView)
        
        setupConstraints()
        altitudeBarLoaded = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print("Got new location")
        
        if(!inStop) {
            if(!mapWasCentered) {
                
                mapWasCentered = true
                let region = MKCoordinateRegionMakeWithDistance(locations.last!.coordinate, 0.01, 0.01)
                
                mapView.setRegion(region, animated: true)
            }
            
            updateLines(newPoint: locations.last!)
            
            
            let pos = DataPoint(lat: locations.last!.coordinate.latitude, lon: locations.last!.coordinate.longitude)
            
            if((currentRoute?.Positions.count)!>0) {
                
                let lastPoint = CLLocation(latitude: (currentRoute?.Positions.last?.lat)!, longitude: (currentRoute?.Positions.last?.lon)!)
                
                let distance = locations.last?.distance(from: lastPoint)
                
                if(distance! >= 10.0) {
                    
                    currentRoute?.Positions.append(pos)
                    currentRoute?.Altitudes.append(DataAltitude(altitude: locations.last!.altitude))
                    
                    mapView.setCenter(locations.last!.coordinate, animated: true)
                }
            }
            else {
                
                currentRoute?.Positions.append(pos)
                currentRoute?.Altitudes.append(DataAltitude(altitude: locations.last!.altitude))
            }
            
            if(altitudeBarLoaded) {
                updateAltimeterGraph()
            }
            if(locations.last!.horizontalAccuracy <= 10) {
                addLabel(withText: "GPS: Good".localized, value: 1.0)
            }
            else if(locations.last!.horizontalAccuracy <= 170) {
                addLabel(withText: "GPS: Not Good".localized, value: 0.5)
            }
            else {
                addLabel(withText: "GPS: Bad".localized, value: 0.0)
            }
            
          //  locationManager.stopUpdatingLocation()
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
        
        oldPositions.append(newPoint.coordinate)
        let route = MKPolyline(coordinates: oldPositions, count: oldPositions.count)
        mapView.add(route)
    }
    
    func updateLines(newPoint: CLLocation) {
        
        let route = MKPolyline(coordinates: (currentRoute?.Positions_in_CLLocationCoordinate2D)!, count: (currentRoute?.Positions.count)!)
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
        
        graphView.backgroundFillColor = UIColor.colorFromHex(hexString: "#333333")
        
        graphView.lineWidth = 1
        graphView.lineColor = UIColor.colorFromHex(hexString: "#777777")
        graphView.lineStyle = ScrollableGraphViewLineStyle.smooth
        
        graphView.shouldFill = true
        graphView.fillType = ScrollableGraphViewFillType.gradient
        graphView.fillColor = UIColor.colorFromHex(hexString: "#555555")
        graphView.fillGradientType = ScrollableGraphViewGradientType.linear
        graphView.fillGradientStartColor = UIColor.colorFromHex(hexString: "#555555")
        graphView.fillGradientEndColor = UIColor.colorFromHex(hexString: "#444444")
        
        graphView.dataPointSpacing = 80
        graphView.dataPointSize = 2
        graphView.dataPointFillColor = UIColor.white
        
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
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "cameraStoryboard") as! PhotoCameraViewController
        
        if(indexPath.row == currentRoute?.Images.count) {
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
        
        
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromLeft  //kCATransitionFromRight
        view.window!.layer.add(transition, forKey: kCATransition)
        self.present(vc, animated: false, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if(currentRoute?.ImagesPositions == nil) {
            return 1
        }
        else {
            return currentRoute!.Images.count + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: POIViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "addCellIdentifier", for: indexPath) as! POIViewCell
        
        if(currentRoute != nil) {
            if(!(currentRoute?.Images.isEmpty)!) {
                if(indexPath.row < (currentRoute?.Images.count)! ) {
                    if (currentRoute?.Images[indexPath.row] != nil) {
                        
                        let data = currentRoute!.Images[indexPath.row].data as Data
                        cell.imageView.image = UIImage(data: data)

                        cell.viewText.strTitle = (self.currentRoute?.ImageDescriptions[indexPath.row].text)!
                        cell.viewText.strDescription = ""
                        
                        
                        DispatchQueue.global(qos: .background).async {
                            cell.imageView.image?.getColors { colors in
                                    cell.viewText.colorText = colors.primary
                                    cell.viewText.reDraw()
                                    cell.lblPlus.isHidden = true
                            }
                        }
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

