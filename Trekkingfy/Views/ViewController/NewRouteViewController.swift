//
//  NewRouteViewController.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 20/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit
import ScrollableGraphView

class NewRouteViewController: UIViewController {

    @IBOutlet var graphView: UIView!
    
    var graphBarView = ScrollableGraphView()
    //var currentGraphType = GraphType.dark
    var graphConstraints = [NSLayoutConstraint]()
    
    let numberOfDataItems = 29
    
    override func viewDidAppear(_ animated: Bool) {
        
        let data: [Double] = self.generateRandomData(self.numberOfDataItems, max: 50)
        let labels: [String] = self.generateSequentialLabels(self.numberOfDataItems, text: "FEB")
        
        // Do any additional setup after loading the view.
        graphBarView = ScrollableGraphView(frame: self.graphView.frame)
        graphBarView = createDarkGraph(self.graphView.frame)

        graphBarView.set(data: data, withLabels: labels)
        
        self.graphView.addSubview(graphBarView)
        
        setupConstraints()

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
    
    private func generateSequentialLabels(_ numberOfItems: Int, text: String) -> [String] {
        var labels = [String]()
        for i in 0 ..< numberOfItems {
            labels.append("\(text) \(i+1)")
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

extension NewRouteViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: POIViewCell
        
        if(indexPath.row == indexPath.count) {
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
