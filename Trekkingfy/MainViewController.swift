//
//  ViewController.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 20/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var routes: [Route] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        loadFooData()
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
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "newRouteView") as! NewRouteViewController
        
        if(indexPath.row == routes.count-1) {
           vc.currentRoute = nil
        }
        else {
            vc.currentRoute = routes[indexPath.row]
        }
        
        self.present(vc, animated: false, completion: nil)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return routes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: RouteViewCell
        
        if(indexPath.row == routes.count-1) {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addCellIdentifier", for: indexPath) as! RouteViewCell
        }
        else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "routeCellIdentifier", for: indexPath) as! RouteViewCell
        }
        return cell
        
    }
}
