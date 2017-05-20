//
//  POIViewCell.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 20/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit

class POIViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func draw(_ rect: CGRect) { //Your code should go here.
        super.draw(rect)
        self.layer.cornerRadius = self.frame.size.width / 2
    }
    
    
}
