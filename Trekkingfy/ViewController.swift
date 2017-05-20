//
//  ViewController.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 20/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ReviewSegue") {
/*            let reviewView = segue.destination as! ReviewViewController
            reviewView.userInfo = userInfos!
            reviewView.delegate = self  */
        }
    }

}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "newRouteView") as! NewRouteViewController
        self.present(vc, animated: false, completion: nil)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: RouteViewCell
        
        if(indexPath.row == indexPath.count) {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addCellIdentifier", for: indexPath) as! RouteViewCell
        }
        else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "routeCellIdentifier", for: indexPath) as! RouteViewCell
        }
        return cell
        
    }
}
