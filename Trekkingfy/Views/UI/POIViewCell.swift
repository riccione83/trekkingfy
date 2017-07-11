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
    
    @IBOutlet var lblPlus: UILabel!
    
    @IBOutlet var viewText: POIViewText!
    
    
    override func draw(_ rect: CGRect) { //Your code should go here.
        
        super.draw(rect)
        self.layer.cornerRadius = self.frame.size.width / 2
    
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let size = self.bounds.size
        
        context.translateBy (x: size.width / 2, y: size.height / 2)
        context.scaleBy (x: 1, y: -1)

        UIGraphicsEndImageContext()
    }
}
