//
//  ViewController.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 20/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, RouteSaveExtension, CLLocationManagerDelegate,UIGestureRecognizerDelegate {
    
    @IBOutlet var routesGrid: UICollectionView!
    
    @IBOutlet var imgWeather1: UIImageView!
    
    @IBOutlet var imgWeather2: UIImageView!
    
    @IBOutlet var imgWeather3: UIImageView!
    
    @IBOutlet var imgWeather4: UIImageView!
    
    @IBOutlet var imgWeather5: UIImageView!
    
    @IBOutlet var imgWeather6: UIImageView!
    
    @IBOutlet var txtWeather: UILabel!
    
    var routes: [Route] = []
    var deleteModeActive = false
    var locationManager = CLLocationManager()
    
    @IBOutlet var btnDelete: UIButton!
    
    @IBAction func btnTrashModeClicked(_ sender: Any) {
    }
    
    func saveNewRoute(route:Route) {

        if(route.ID! > -1) {
            var i=0;
            for r in routes {
                if(r.ID == route.ID)
                {
                    routes[i]=route
                    break
                }
                i = i + 1
            }
        }
        else {
            route.ID = routes.count
            routes.append(route)
        }
        let userDefaults = UserDefaults.standard
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: routes)
        userDefaults.set(encodedData, forKey: "routes")
        userDefaults.synchronize()
        
        routesGrid.reloadData()
        print("Save new Route!!")
    }
    
    func saveRoutes() {
        let userDefaults = UserDefaults.standard
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: routes)
        userDefaults.set(encodedData, forKey: "routes")
        userDefaults.synchronize()
        
        routesGrid.reloadData()
    }

    
    func loadRoutes() -> [Route] {
        let userDefaults = UserDefaults.standard
        let decoded  = userDefaults.object(forKey: "routes") as? Data
        if(decoded != nil) {
            return NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [Route]
        }
        else {
            return [Route]()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        routes = loadRoutes()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(gestureReconizer:)))
        let touchr = UITapGestureRecognizer(target: self, action: #selector(self.handleShortPress(gestureReconizer:)))
        
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.routesGrid.addGestureRecognizer(lpgr)
        self.routesGrid.addGestureRecognizer(touchr)
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
        
        if(deleteModeActive && routes.count > 0) {
           
            if((indexPath?.row)! < routes.count) {
                routes.remove(at: (indexPath?.row)!)
                saveRoutes()
                if(routes.count == 0) {
                    deleteModeActive = false
                }
            }
            routesGrid.reloadData()
        }
        else {
            if(!deleteModeActive) {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "newRouteView") as! NewRouteViewController
                vc.mainView = self
                if(indexPath?.row == routes.count || (routes.count-1) == -1) {
                    vc.currentRoute = nil
                }
                else {
                    vc.currentRoute = routes[(indexPath?.row)!]
                }
                
                self.present(vc, animated: false, completion: nil)
            }
        }

    }
    
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizerState.ended {
            return
        }
    
        let p = gestureReconizer.location(in: self.routesGrid)
        let indexPath = self.routesGrid.indexPathForItem(at: p)
        
        if let index = indexPath {
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
        let latestLocation: AnyObject = locations[locations.count - 1]
        
        let lat = latestLocation.coordinate.latitude
        let lon = latestLocation.coordinate.longitude
        
        // Put together a URL With lat and lon
        let path = "https://api.darksky.net/forecast/0700af8905319f26ca64fe4593680056/\(lat),\(lon)?lang=it&units=si"
        print(path)
        
        let url = NSURL(string: path)
        
        let task = URLSession.shared.dataTask(with: url! as URL) { (data, response, error) in
            DispatchQueue.main.async(execute: {
                if(data != nil) {
                    self.extractData(weatherData: data! as NSData)
                    self.locationManager.stopUpdatingLocation()
                }
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
                    // locationName = name
                    txtWeather.text = desc
                }
            }

        }
       // return (locationName,temperature)
    }
    
    private func loadFooData() {
        let numberOfItems = 5
        
        for i in 0...numberOfItems {
            routes.append(Route())
            for _ in 0...100 {
                routes[i].Altitudes.append(Double(arc4random()).truncatingRemainder(dividingBy: 1000))
            }
        }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if(!deleteModeActive) {
        
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "newRouteViewNavigationController") as! NewRouteViewController
            
            
            vc.mainView = self
            if(indexPath.row == routes.count || (routes.count-1) == -1) {
                vc.currentRoute = nil
            }
            else {
                vc.currentRoute = routes[indexPath.row]
            }
            
           self.present(vc, animated: false, completion: nil)
        }
        else {
            if(indexPath.row < routes.count) {
                routes.remove(at: indexPath.row)

                saveRoutes()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(routes.count == 0) {
            return 1
        }
        else {
            return routes.count + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: RouteViewCell
        
        if(indexPath.row == routes.count || (routes.count-1 == -1)) {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addCellIdentifier", for: indexPath) as! RouteViewCell
        }
        else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "routeCellIdentifier", for: indexPath) as! RouteViewCell
            
            if(deleteModeActive) {
                cell.imgClose.isHidden = false
                cell.backgroundColor = UIColor.red
                
                cell.contentView.layer.cornerRadius = 10
                cell.contentView.layer.borderWidth = 1
                cell.contentView.layer.borderColor = UIColor.clear.cgColor
                cell.contentView.layer.masksToBounds = true
                
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
