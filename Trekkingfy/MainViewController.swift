//
//  ViewController.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 20/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit

class ViewController: UIViewController, RouteSaveExtension {
    
    @IBOutlet var routesGrid: UICollectionView!
    
    var routes: [Route] = []
    var deleteModeActive = false
    
    @IBOutlet var btnDelete: UIButton!
    
    @IBAction func btnTrashModeClicked(_ sender: Any) {
        deleteModeActive = !deleteModeActive
        
        if(deleteModeActive) {
            btnDelete.setTitle("Done", for: UIControlState.normal)
        }
        else {
            btnDelete.setTitle("Delete", for: UIControlState.normal)
        }
        
        routesGrid.reloadData()
    }
    
    func saveNewRoute(route:Route) {
        print("Save new Route!!")
        if(route.ID! > -1) {
            return
        }
        route.ID = routes.count
        routes.append(route)
        let userDefaults = UserDefaults.standard
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: routes)
        userDefaults.set(encodedData, forKey: "routes")
        userDefaults.synchronize()
        
        routesGrid.reloadData()
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
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ReviewSegue") {
/*            let reviewView = segue.destination as! ReviewViewController
            reviewView.userInfo = userInfos!
            reviewView.delegate = self  */
        }
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
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "newRouteView") as! NewRouteViewController
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
                cell.backgroundColor = UIColor.red
            }
            else {
                cell.backgroundColor = UIColor.clear
            }
        }
        
        return cell
        
    }
}
