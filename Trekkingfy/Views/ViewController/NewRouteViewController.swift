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

protocol RouteSaveExtension {
    
    func saveNewRoute(route:Route)
    
}

class NewRouteViewController: UIViewController, CLLocationManagerDelegate,UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet var graphView: UIView!
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var imagePositionGrid: UICollectionView!
    var mainView:RouteSaveExtension? = nil
    
    let updateLocationInterval = 5  //5 secs
    var timerUpdateLocation:Timer? = nil
    
    var currentRoute:Route?
    var altitudeBarLoaded = false
    //private var locationManager = AppDelegate().locationManager
    
    var locationManager = CLLocationManager()
    
    var graphBarView = ScrollableGraphView()
    var graphConstraints = [NSLayoutConstraint]()
    var label = UILabel()
    var labelConstraints = [NSLayoutConstraint]()
    
    @IBAction func returnToMainAndSave(_ sender: Any) {
            self.dismiss(animated: true) { 
                self.locationManager.stopUpdatingLocation()
                self.timerUpdateLocation = nil
                UIApplication.shared.isIdleTimerDisabled = false
                if(self.mainView != nil) {
                    self.mainView?.saveNewRoute(route: self.currentRoute!)
                }
        }
    }
    
    
    @IBAction func btnSOSClicked(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SOSModeViewController") as! SOSModeViewController
        vc.endPoint = currentRoute!.Positions.first
        locationManager.stopUpdatingLocation()
        //locationManager = nil
        
        self.present(vc, animated: false, completion: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Do any additional setup after loading the view.
        UIApplication.shared.isIdleTimerDisabled = true
        
        setupUI()
        
        timerUpdateLocation = Timer.scheduledTimer(timeInterval: TimeInterval(updateLocationInterval), target: self, selector: #selector(self.updateNewLocationTimer), userInfo: nil, repeats: true)
        
    }
    
    func updateNewLocationTimer() {
        
        locationManager.startUpdatingLocation()
    }
    
    private func updateAltimeterGraph() {
        
        let data:[Double] = Array(currentRoute!.Altitudes.suffix(5))
        if(currentRoute!.Altitudes.count > 0) {
            graphBarView.set(data: data, withLabels: self.generateSequentialLabels(data.count, texts:data))
        }
        
    }
    
    private func setupUI() {
        
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        graphBarView = ScrollableGraphView(frame: self.graphView.frame)
        graphBarView = createDarkGraph(self.graphView.frame)
        
        if(currentRoute == nil) {
            currentRoute = Route()
            currentRoute!.ID = -1
            let data: [Double] = [0]
            graphBarView.set(data: data, withLabels: self.generateSequentialLabels(1, texts: data))
            
            locationManager.delegate = self
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        else {
            let data:[Double] = Array(currentRoute!.Altitudes)
            if(currentRoute!.Altitudes.count > 0) {
                graphBarView.set(data: data, withLabels: self.generateSequentialLabels(data.count, texts:data))
            }
            var loc:CLLocation = CLLocation()
            for p in currentRoute!.Positions {
                loc = CLLocation(latitude: p.lat!, longitude: p.lon!)
                updateLines(newPoint: loc)
            }

            
            let startPoint = CLLocation(latitude: (currentRoute?.Positions.first?.lat!)!, longitude: (currentRoute?.Positions.first?.lon!)!)
            setInitialPoint(start_point: startPoint)
            
            let finalPoint = CLLocation(latitude: (currentRoute?.Positions.last?.lat!)!, longitude: (currentRoute?.Positions.last?.lon!)!)
            setFinalPoint(start_point: finalPoint)
            
            let region = MKCoordinateRegionMakeWithDistance(loc.coordinate, 100, 100)
            mapView.setRegion(region, animated: true)
            //mapView.setCenter(loc.coordinate, animated: true)
            
        }
        
        self.graphView.addSubview(graphBarView)
        
        setupConstraints()
        altitudeBarLoaded = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //let region = MKCoordinateRegionMake(locations.last!.coordinate, MKCoordinateSpanMake(0.002, 0.002))
        let region = MKCoordinateRegionMakeWithDistance(locations.last!.coordinate, 100, 100)
        
        
        
        
        mapView.setRegion(region, animated: true)
        mapView.setCenter(locations.last!.coordinate, animated: true)
        updateLines(newPoint: locations.last!)
        
        if(currentRoute!.Positions.count>0) {
       
            let lastPoint = CLLocation(latitude: (currentRoute!.Positions.last?.lat)!, longitude: (currentRoute!.Positions.last?.lon)!)
        
            let distance = locations.last?.distance(from: lastPoint)
            
            if(distance! >= 10.0) {
            
                currentRoute?.Positions.append(Point(val: locations.last!.coordinate))
                currentRoute?.Altitudes.append(locations.last!.altitude)
            }
        }
        else {
            
            currentRoute?.Positions.append(Point(val: locations.last!.coordinate))
            currentRoute?.Altitudes.append(locations.last!.altitude)
        }
        
//        currentRoute?.Altitudes.append(Double(arc4random()).truncatingRemainder(dividingBy: 1000))
        if(altitudeBarLoaded) {
            updateAltimeterGraph()
        }
        if(locations.last!.horizontalAccuracy <= 10) {
            addLabel(withText: "GPS: Good", value: 1.0)
        }
        else if(locations.last!.horizontalAccuracy <= 170) {
            addLabel(withText: "GPS: Not Good", value: 0.5)
        }
        else {
            addLabel(withText: "GPS: Bad", value: 0.0)
        }
        
        locationManager.stopUpdatingLocation()
    }
    
    func setInitialPoint(start_point:CLLocation) {
        
        let point = MKPointAnnotation()
        point.coordinate = start_point.coordinate
        point.title = "Start"
        mapView.addAnnotation(point)
        //mapView.selectAnnotation(point, animated: true)
    }

    func setFinalPoint(start_point:CLLocation) {
        
        let point = MKPointAnnotation()
        point.coordinate = start_point.coordinate
        point.title = "Stop"
        mapView.addAnnotation(point)
        mapView.selectAnnotation(point, animated: true)
    }

    func updateLines(newPoint: CLLocation) {
    
        //currentRoute?.Positions.append(Point(val: newPoint.coordinate))
        let route = MKPolyline(coordinates: currentRoute!.Positions_in_CLLocationCoordinate2D, count: currentRoute!.Positions.count)
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
        
        //setupUI()
    }
    
    // Data Generation
    private func generateRandomData(_ numberOfItems: Int, max: Double) -> [Double] {
        var data = [Double]()
        for _ in 0 ..< numberOfItems {
            var randomNumber = Double(arc4random()).truncatingRemainder(dividingBy: max)
            
            if(arc4random() % 100 < 10) {
                randomNumber *= 3
            }
            
            data.append(randomNumber)
        }
        return data
    }
    
    private func generateSequentialLabels(_ numberOfItems: Int, texts: [Double]) -> [String] {
        var labels = [String]()
        
        for i in 0 ..< numberOfItems {
            labels.append("mt: \(texts[i])")
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
        
        if(indexPath.row == currentRoute!.ImagesPositions.count) {
            
            self.currentRoute?.ImagesPositions.append(Point(val: self.locationManager.location!.coordinate))
            
            collectionView.performBatchUpdates({
                let indexSet = IndexSet(integer: 0)
                self.imagePositionGrid.reloadSections(indexSet)
            }, completion: nil)
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if(currentRoute?.ImagesPositions == nil) {
            return 1
        }
        else {
            return currentRoute!.ImagesPositions.count + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: POIViewCell
        
        if(currentRoute == nil || indexPath.row == currentRoute!.ImagesPositions.count) {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addCellIdentifier", for: indexPath) as! POIViewCell
        }
        else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addCellIdentifier", for: indexPath) as! POIViewCell
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

