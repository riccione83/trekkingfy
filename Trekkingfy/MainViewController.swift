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
import StoreKit

class ViewController: UIViewController, RouteSaveExtension,UIGestureRecognizerDelegate,LocationManagerDelegate {
    
    @IBOutlet var routesGrid: UICollectionView!
    @IBOutlet var imgWeather1: UIImageView!
    @IBOutlet var imgWeather2: UIImageView!
    @IBOutlet var imgWeather3: UIImageView!
    @IBOutlet var imgWeather4: UIImageView!
    @IBOutlet var imgWeather5: UIImageView!
    @IBOutlet var imgWeather6: UIImageView!
    @IBOutlet var txtWeather: UILabel!
    
    var deleteModeActive = false
    
    var locationServicesEnabled = true
    
    @IBOutlet var btnDelete: UIButton!
    var isPurchased = false
    var products = [SKProduct]()
    let useInAppPurchase = true
    
    
    @IBAction func btnTrashModeClicked(_ sender: Any) {
    }
    
    func handlePurchaseNotification(_ notification: Notification) {
        guard let productID = notification.object as? String else { return }
        
        for (_, product) in products.enumerated() {
            guard product.productIdentifier == productID else { continue }
            
            print(product.productIdentifier)
        }
        self.isPurchased = true
    }
    
    func isAppPurchased() -> Bool {
        guard products.count > 0 else {return false}
        let product = products[0]
        return TrekkingfyProducts.store.isProductPurchased(product.productIdentifier)
    }
    
    func buyFullApp() {
        let product = products[0]
        TrekkingfyProducts.store.buyProduct(product)
    }
    
    func restoreApp() {
        TrekkingfyProducts.store.restorePurchases()
    }
    
    func saveNewRoute(route:Route) {
        if(route.ID == -1) {
            route.ID = DBManager.sharedInstance.getNewID() + 1 // .getDataFromDB().count + 1
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
        
        TrekkingfyProducts.store.requestProducts{success, products in
            if success {
                self.products = products!
                self.isPurchased = TrekkingfyProducts.store.isProductPurchased(products![0].productIdentifier)
                
            }
            // self.isPurchased = self.isAppPurchased()
        }
        
        LocationService.sharedInstance.delegate = self
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handlePurchaseNotification(_:)),
                                               name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
                                               object: nil)
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
                
                //Here
                let alert = UIAlertController(title: "Deleting".localized, message: "Are you sure to delete this route?".localized, preferredStyle: UIAlertControllerStyle.alert)
                
                alert.addAction(UIAlertAction(title: "Yes".localized, style: .default, handler: { (UIAlertAction) in
                    
                    let item = DBManager.sharedInstance.getDataFromDB()[(indexPath?.row)!]
                    
                    DBManager.sharedInstance.deleteFromDb(object: item)
                    if(DBManager.sharedInstance.getDataFromDB().count == 0) {
                        self.deleteModeActive = false
                    }
                    
                    self.routesGrid.deleteItems(at: [indexPath!])
                    
                  /*  UIView.transition(with: self.routesGrid, duration: 1.0, options: .transitionCrossDissolve, animations: {
                        //Do the data reload here
                        self.routesGrid.reloadData()
                    }, completion: nil)
 */
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { (UIAlertAction) in
                }))
                
                self.present(alert, animated: true, completion: nil)
                
                
                //Here
            }
            
        }
        else {
            if(!deleteModeActive) {
                if locationServicesEnabled {
                    
                    //DispatchQueue.main.async(execute: {
                    
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "newRouteView") as! NewRouteViewController
                    vc.mainView = self
                    let routeCount = DBManager.sharedInstance.getDataFromDB().count
                    if(indexPath?.row == routeCount || (DBManager.sharedInstance.getDataFromDB().count-1) == -1) {
                        
                        self.isPurchased = isAppPurchased()
                        
                        if self.products.count == 0
                        {
                            self.isPurchased = true
                            
                        }
                        
                        print("App Purchased: \(self.isPurchased)")
                        if self.useInAppPurchase {
                            if !self.isPurchased {
                                if routeCount >= 8 {
                                    self.tryToBuyApp()
                                }
                                else {
                                    self.present(vc, animated: false, completion: nil)
                                }
                            }
                            else
                            {
                                self.present(vc, animated: false, completion: nil)
                            }
                        }
                        else {
                            self.present(vc, animated: false, completion: nil)
                        }
                    }
                    else {
                        vc.currentRoute = DBManager.sharedInstance.getDataFromDB()[(indexPath?.row)!]
                        self.present(vc, animated: false, completion: nil)
                    }
                    //        })
                }
            }
            else {
                self.deleteModeActive = false
            }
        }
    }
    
    func tryToBuyApp(){
        let product = products[0]
        let alert = UIAlertController(title: product.localizedTitle, message: "With the Full App Purchased you can save all you Route, forever.".localized, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Buy the Full App".localized, style: .default, handler: { (UIAlertAction) in
            print("Start to buy the full App")
            self.buyFullApp()
        }))
        
        alert.addAction(UIAlertAction(title: "Restore my purchases".localized, style: .default, handler: { (UIAlertAction) in
            print("Restore the App")
            self.restoreApp()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
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
    
    
    func tracingLocationDidFailWithError(_ error: NSError) {
        locationServicesEnabled = false
        txtWeather.text = "Please enable GPS Services for Trekkingy".localized
    }
    
    func tracingHeading(_ currentHeading: CLHeading) {
        
    }
    
    
    //func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    func tracingLocation(_ currentLocation: CLLocation) {
        let latestLocation: AnyObject = currentLocation //locations[locations.count - 1]
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
                LocationService.sharedInstance.stopUpdatingLocation()
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
            
            let distanceInMeters = DBManager.sharedInstance.getDataFromDB()[indexPath.row].TotalDistance
            if(distanceInMeters < 1000) {
                cell.txtDistance.text = "Distance:".localized + " \(distanceInMeters.roundTo(places: 0)) mt"
            }
            else {
                cell.txtDistance.text = "Distance:".localized +  " \((distanceInMeters/1000).roundTo(places: 2)) km"
            }
            
            let created = DBManager.sharedInstance.getDataFromDB()[indexPath.row].createdAt ///.to_string()
            let date =  formatter.string(from: created)
            cell.lblCreatedAt.text = date //formatter.date(from: created)!.to_string()
            cell.txtRouteName.text = DBManager.sharedInstance.getDataFromDB()[indexPath.row].Name
            
            cell.imgCarousel.alpha = 0.3
            if(DBManager.sharedInstance.getDataFromDB()[indexPath.row].Images.count>0) {
                
                //let rnd = arc4random_uniform(UInt32(DBManager.sharedInstance.getDataFromDB()[indexPath.row].Images.count))
                //cell.imgCarousel.image = UIImage(data: DBManager.sharedInstance.getDataFromDB()[indexPath.row].Images[Int(rnd)].data as Data)
                cell.imgCarousel.image = UIImage(data: DBManager.sharedInstance.getDataFromDB()[indexPath.row].Images[0].data as Data)
            }
            else
            {
                //let index = arc4random_uniform(3) + 1
                //let image_name = "route_\(index)"
                let image_name = "route_1"
                cell.imgCarousel.image = UIImage(named: image_name)
            }
            
            if(deleteModeActive) {
                cell.imgClose.isHidden = false
                //cell.backgroundColor = UIColor.red
                
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
