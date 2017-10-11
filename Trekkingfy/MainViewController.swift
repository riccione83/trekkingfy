//
//  ViewController.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 20/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

class ViewController: UIViewController, RouteSaveExtension, CLLocationManagerDelegate,UIGestureRecognizerDelegate {
    
    @IBOutlet var routesGrid: UICollectionView!
    @IBOutlet var imgWeather1: UIImageView!
    @IBOutlet var imgWeather2: UIImageView!
    @IBOutlet var imgWeather3: UIImageView!
    @IBOutlet var imgWeather4: UIImageView!
    @IBOutlet var imgWeather5: UIImageView!
    @IBOutlet var imgWeather6: UIImageView!
    @IBOutlet var txtWeather: UILabel!
    
    var deleteModeActive = false
    var locationManager = CLLocationManager()
    var locationServicesEnabled = true
    
    @IBOutlet var btnDelete: UIButton!
    
    @IBAction func btnTrashModeClicked(_ sender: Any) {
    }
    
    func saveNewRoute(route:Route) {
        if(route.ID == -1) {
            route.ID = DBManager.sharedInstance.getDataFromDB().count
            let date = Date()
            route.createdAt =  date
        }
        DBManager.sharedInstance.addData(object: route)
        routesGrid.reloadData()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationServicesEnabled = true
        default:
            locationServicesEnabled = false
            txtWeather.text = "Please enable GPS Services for Trekkingy".localized
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(gestureReconizer:)))
        let touchr = UITapGestureRecognizer(target: self, action: #selector(self.handleShortPress(gestureReconizer:)))
        
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.routesGrid.addGestureRecognizer(lpgr)
        self.routesGrid.addGestureRecognizer(touchr)
        
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined, .restricted, .denied:
                locationServicesEnabled = false
            case .authorizedAlways, .authorizedWhenInUse:
                locationServicesEnabled = true
            }
        } else {
            print("Location services are not enabled")
            locationServicesEnabled = false
        }
    }
    
    func handleShortPress(gestureReconizer: UITapGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizerState.ended {
            return
        }
        let p = gestureReconizer.location(in: self.routesGrid)
        let indexPath = self.routesGrid.indexPathForItem(at: p)
        
        if(indexPath == nil) {
            if(deleteModeActive) {
                deleteModeActive = false
                routesGrid.reloadData()
            }
            return
        }
        
        if(deleteModeActive && DBManager.sharedInstance.getDataFromDB().count > 0) { //routes.count > 0) {
            
            if((indexPath?.row)! < DBManager.sharedInstance.getDataFromDB().count) {//routes.count) {
                
                let item = DBManager.sharedInstance.getDataFromDB()[(indexPath?.row)!]
                
                DBManager.sharedInstance.deleteFromDb(object: item)
                if(DBManager.sharedInstance.getDataFromDB().count == 0) {
                    deleteModeActive = false
                }
            }
            routesGrid.reloadData()
        }
        else {
            if(!deleteModeActive) {
                if locationServicesEnabled {
                    DispatchQueue.main.async(execute: {
                        let vc = self.storyboard?.instantiateViewController(withIdentifier: "newRouteView") as! NewRouteViewController
                        vc.mainView = self
                        if(indexPath?.row == DBManager.sharedInstance.getDataFromDB().count || (DBManager.sharedInstance.getDataFromDB().count-1) == -1) {
                        }
                        else {
                            vc.currentRoute = DBManager.sharedInstance.getDataFromDB()[(indexPath?.row)!]
                        }
                        
                        self.present(vc, animated: false, completion: nil)
                    })
                }
            }
        }
        
    }
    
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizerState.ended {
            return
        }
        
        let p = gestureReconizer.location(in: self.routesGrid)
        let indexPath = self.routesGrid.indexPathForItem(at: p)
        
        if indexPath != nil {
            deleteModeActive = true
            routesGrid.reloadData()
            
        } else {
            print("Could not find index path")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ReviewSegue") {
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        let latestLocation: AnyObject = locations[locations.count - 1]
        var language = ""
        let lat = latestLocation.coordinate.latitude
        let lon = latestLocation.coordinate.longitude
        
        if let pre = Locale.current.languageCode { // .preferredLanguages[0].localizedLowercase
            language = pre
        }
        else {
            language = "en"
        }
        
        // Put together a URL With lat and lon
        let path = "https://api.darksky.net/forecast/0700af8905319f26ca64fe4593680056/\(lat),\(lon)?lang=\(language)&units=si"
        print(path)
        
        let url = NSURL(string: path)
        
        let task = URLSession.shared.dataTask(with: url! as URL) { (data, response, error) in
            DispatchQueue.main.async(execute: {
                if(data != nil) {
                    self.extractData(weatherData: data! as NSData)
                }
                else
                {
                    self.txtWeather.text = "Error on getting forecast data".localized
                }
                self.locationManager.stopUpdatingLocation()
            })
        }
        
        task.resume()
    }
    
    func extractData(weatherData: NSData)  {
        
        var temperature = ""
        var weatherIcon:[String]? = []
        
        let json = try? JSONSerialization.jsonObject(with: weatherData as Data, options: []) as! NSDictionary
        
        if json != nil {
            if let min = json!["hourly"] as? NSDictionary {
                if let desc = min["summary"] as? String {
                    let icon = min["icon"] as? String
                    txtWeather.text = desc
                    imgWeather1.image = UIImage(named: icon!)
                }
                if let data = min["data"] as? NSArray {
                    for i in 0...5 {
                        if let min = data[i] as? NSDictionary {
                            weatherIcon?.append(min["icon"] as! String)
                        }
                    }
                    imgWeather2.image = UIImage(named: (weatherIcon?[0])!)
                    imgWeather3.image = UIImage(named: (weatherIcon?[1])!)
                    imgWeather4.image = UIImage(named: (weatherIcon?[2])!)
                    imgWeather5.image = UIImage(named: (weatherIcon?[3])!)
                    imgWeather6.image = UIImage(named: (weatherIcon?[4])!)
                }
            }
            
            if let main = json!["currently"] as? NSDictionary {
                if let temp = main["temperature"] as? Double {
                    temperature = String(format: "%.0f", temp)
                    txtWeather.text = txtWeather.text! + " (\(temperature)°C)"
                }
            }
            
            if let min = json!["hourly"] as? NSDictionary {
                if let desc = min["summary"] as? String {
                    txtWeather.text = desc
                }
            }
            
        }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(DBManager.sharedInstance.getDataFromDB().count == 0) {
            return 1
        }
        else {
            return DBManager.sharedInstance.getDataFromDB().count + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: RouteViewCell
        var dateFormat: String
        
        switch NSLocale.current.identifier {
        case "it_IT":
            dateFormat = "dd/MM/yyyy HH:mm"
        default:
            dateFormat = "dd/MM/yyyy h:mm a"//"yyyy-MM-dd hh:mm"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        
        
        if(indexPath.row == DBManager.sharedInstance.getDataFromDB().count || (DBManager.sharedInstance.getDataFromDB().count-1 == -1)) {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addCellIdentifier", for: indexPath) as! RouteViewCell
        }
        else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "routeCellIdentifier", for: indexPath) as! RouteViewCell
            
            cell.contentView.layer.cornerRadius = 10
            cell.contentView.layer.borderWidth = 1
            cell.contentView.layer.borderColor = UIColor.clear.cgColor
            cell.contentView.layer.masksToBounds = true
            
            
            let created = DBManager.sharedInstance.getDataFromDB()[indexPath.row].createdAt ///.to_string()
            let date =  formatter.string(from: created)
            cell.lblCreatedAt.text = date //formatter.date(from: created)!.to_string()
            
            cell.txtRouteName.text = DBManager.sharedInstance.getDataFromDB()[indexPath.row].Name
            
            if(DBManager.sharedInstance.getDataFromDB()[indexPath.row].Images.count>0) {
                
                let rnd = arc4random_uniform(UInt32(DBManager.sharedInstance.getDataFromDB()[indexPath.row].Images.count))
                cell.imgCarousel.image = UIImage(data: DBManager.sharedInstance.getDataFromDB()[indexPath.row].Images[Int(rnd)].data as Data)
            }
            else
            {
                let index = arc4random_uniform(3) + 1
                let image_name = "route_\(index)"
                cell.imgCarousel.image = UIImage(named: image_name)
                
            }
            
            if(deleteModeActive) {
                cell.imgClose.isHidden = false
                cell.backgroundColor = UIColor.red
                
                cell.layer.shadowColor = UIColor.lightGray.cgColor
                cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                cell.layer.shadowRadius = 2.0
                cell.layer.shadowOpacity = 1.0
                cell.layer.masksToBounds = false
                cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
                
                
                let transformAnim  = CAKeyframeAnimation(keyPath:"transform")
                transformAnim.values  = [NSValue(caTransform3D: CATransform3DMakeRotation(0.04, 0.0, 0.0, 1.0)),NSValue(caTransform3D: CATransform3DMakeRotation(-0.04 , 0, 0, 1))]
                transformAnim.autoreverses = true
                let dur = Double(indexPath.row).truncatingRemainder(dividingBy: 2.0)
                transformAnim.duration  = dur == 0 ?   0.115 : 0.105
                transformAnim.repeatCount = Float.infinity
                cell.layer.add(transformAnim, forKey: "transform")
                
            }
            else {
                cell.imgClose.isHidden = true
                cell.backgroundColor = UIColor.clear
                cell.layer.shadowColor = UIColor.clear.cgColor
            }
        }
        
        return cell
        
    }
}
