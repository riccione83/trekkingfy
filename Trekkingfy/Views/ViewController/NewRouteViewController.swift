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

class NewRouteViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet var graphView: UIView!
    @IBOutlet var mapView: MKMapView!
    
    var mainView:RouteSaveExtension? = nil
    
    let updateLocationInterval = 5  //5 secs
    var timerUpdateLocation:Timer? = nil
    
    var currentRoute:Route?
    var altitudeBarLoaded = false
    let locationManager:CLLocationManager = CLLocationManager()
    
    var graphBarView = ScrollableGraphView()
    var graphConstraints = [NSLayoutConstraint]()
    var label = UILabel()
    var labelConstraints = [NSLayoutConstraint]()
    
    var numberOfDataItems = 1
    
    
    @IBAction func returnToMainAndSave(_ sender: Any) {
            self.dismiss(animated: true) { 
                self.locationManager.stopUpdatingLocation()
                self.timerUpdateLocation = nil
                if(self.mainView != nil) {
                    self.mainView?.saveNewRoute(route: self.currentRoute!)
                }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Do any additional setup after loading the view.
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
            let region = MKCoordinateRegionMake(loc.coordinate, MKCoordinateSpanMake(0.002, 0.002))
            
            mapView.setRegion(region, animated: true)
            mapView.setCenter(loc.coordinate, animated: true)
        }
        
        self.graphView.addSubview(graphBarView)
        
        setupConstraints()
        altitudeBarLoaded = true
    
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let region = MKCoordinateRegionMake(locations.last!.coordinate, MKCoordinateSpanMake(0.002, 0.002))
        
        mapView.setRegion(region, animated: true)
        mapView.setCenter(locations.last!.coordinate, animated: true)
        updateLines(newPoint: locations.last!)
        
        if(currentRoute?.Positions.last?.lat != locations.last!.coordinate.latitude || currentRoute?.Positions.last?.lon != locations.last!.coordinate.longitude) {
            
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
    
    func updateLines(newPoint: CLLocation) {
    
        currentRoute?.Positions.append(Point(val: newPoint.coordinate))
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

/*

-(void) setInitialPoint:(CLLocation*)start_loc {
    MKPointAnnotation *point = [[MKPointAnnotation alloc]init];
    point.coordinate = start_loc.coordinate;
    point.title = NSLocalizedString(@"Start",nil);
    firstPoint = start_loc;
    startPoint = point;
    [myMap addAnnotation:point];
    [myMap selectAnnotation:point animated:TRUE];
}

-(void) setFinalPoint{
    MKPointAnnotation *point = [[MKPointAnnotation alloc]init];
    point.coordinate = lastPoint.coordinate;
    point.title = NSLocalizedString(@"End",nil);;
    endPoint = point;
    [myMap addAnnotation:point];
    
    [myMap selectAnnotation:point animated:TRUE];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    float const kph = 3.6;
    float const mph = 2.23693629;
    float speed = 0.0;
    
    NSString *unit = @"";
    
    pos = [locations lastObject];
    
    MKCoordinateRegion reg = MKCoordinateRegionMake(pos.coordinate, MKCoordinateSpanMake(0.002, 0.002));
    
    if(!regionCreated) {
        [myMap setRegion:reg];
        regionCreated = true;
    }
    
    [myMap setCenterCoordinate:pos.coordinate];
    
    if(RUNNING) {
        
        [myMap setCenterCoordinate:pos.coordinate];
        [self updateLines:pos];
        
        if(firstPoint==nil)
        {
            firstPoint = pos;
            [self setInitialPoint:firstPoint];
        }
        else
        lastPoint = pos;
        
        
        if(pos.verticalAccuracy<=100.0)
        {
            if(![statusLabel.text isEqualToString:NSLocalizedString(@"Running...",nil)])
            statusLabel.text =NSLocalizedString(@"Running...",nil);
            
            gpsLabel.textColor = [UIColor greenColor];
            
            if(timeTimer==nil)
            {
                timeTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timer) userInfo:nil repeats:YES];
                
                backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                    NSLog(@"Background handle called, Not running background task anymore");
                    [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
                    backgroundTask = UIBackgroundTaskInvalid;
                    }];
            }
            
            
            if(oldPos!=nil)
            {
                CLLocationDistance meters = [pos distanceFromLocation:oldPos];
                distanceInMeters += meters;
            }
            oldPos = pos;
            
            distanceInKM = distanceInMeters/1000;
            if(distanceInMeters<1000)
            {
                unit = @"mt";
                lblDistance.text = [NSString stringWithFormat:@"%.01f %@",distanceInMeters,unit];
                
            }
            else
            {
                unit = @"km";
                lblDistance.text = [NSString stringWithFormat:@"%.02f %@",distanceInKM,unit];
            }
            
            if(distanceInMeters<1000)
            iseDistance = distanceInMeters;
            else
            iseDistance = distanceInKM;
            
            
            if(isKmh) {
                speed = pos.speed * kph;
            }
            else {
                speed = pos.speed * mph;
            }
            
            if(speed<0) speed=0.0;
            
            lastSpeed = speed;
            lblAltitude.text = [NSString stringWithFormat:@"%.0f mt",pos.altitude];
            lblSpeed.text = [NSString stringWithFormat:@"%.0f", speed];
            
            
            //DA VERIFICARE se il codice sotto è valido
            iseAltitude = pos.altitude;
            /*if(iseAltitude==0)
             {
             iseAltitude = pos.altitude;
             }
             else if(pos.altitude>iseAltitude)
             {
             iseAltitude = pos.altitude;
             }
             */
            
            //Verifica la velocità attuale e cambia il massimo
            //per rappresentarlo in basso nella UI
            if(speed<=50)
            viewSpeed.maxValue = 50;
            else if(speed>50 && speed<=100)
            viewSpeed.maxValue = 100;
            else if(speed>100 && speed<=200)
            viewSpeed.maxValue = 200;
            else if(speed>200)
            viewSpeed.maxValue = 400;
            
            //Viene verificato se la velocità attuale è > della velocità massima
            //se è così viene aggiornata la variabile
            if(iseMaxSpeed==0)
            iseMaxSpeed = speed;
            else if(speed>iseMaxSpeed)
            {
                iseMaxSpeed = speed;
            }
            
            viewSpeed.percent = speed;
            [viewSpeed setNeedsDisplay];
            
            //Calcolo del ritmo medio
            lblRitmoMedio.text = [self calcRitmoMedio];
            
            //Calcolo della velocità media
            num_of_point++;
            tempAvgSpeed += speed;
            iseAvgSpeed = (tempAvgSpeed/num_of_point);
            
            
            //Visualizza le calorie bruciate
            [self getCalorieForSession];
            
        }
        else
        {
            gpsLabel.textColor = [UIColor redColor];
            statusLabel.text =NSLocalizedString(@"Waiting for a better gps signal...",nil);
            [self speechText:NSLocalizedString(@"Waiting for a better gps signal...", nil)];
            [timeTimer invalidate];
            timeTimer = nil;
            if(backgroundTask != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
                backgroundTask = UIBackgroundTaskInvalid;
            }
            
        }
    }
    
}

*/

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

extension NewRouteViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfDataItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: POIViewCell
        
        if(indexPath.row == numberOfDataItems - 1) {
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
