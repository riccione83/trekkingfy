//
//  FingerAnimationView.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 04/04/18.
//  Copyright © 2018 Riccardo Rizzo. All rights reserved.
//

import UIKit

class FingerAnimationView: UIView {
    
    internal let fingerImageView = UIImageView(image: UIImage(named: "Finger"))
    public var labelText = "Swipe Up or Down to Open".localized
    
    final func initUI() {
        self.backgroundColor = UIColor.clear
        self.fingerImageView.frame = CGRect(x: 0, y: 0, width: 476/4, height: 575/4)
        self.addSubview(fingerImageView)
        self.isHidden = true
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 476/2, height: 21))
        label.center = CGPoint(x: self.fingerImageView.center.x + 20, y: self.fingerImageView.frame.width + 35)
        label.textAlignment = .center
        label.font = UIFont(name: label.font.fontName, size: 10)
        label.text = labelText
        self.addSubview(label)
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initUI()
    }
    
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
