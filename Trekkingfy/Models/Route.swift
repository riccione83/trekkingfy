//
//  Route.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 20/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit
import MapKit

class Point:NSObject,NSCoding {
    var lat:Double? = 0.0
    var lon:Double? = 0.0
    
    convenience init(val:CLLocationCoordinate2D) {
        self.init()
        self.lat = val.latitude
        self.lon = val.longitude
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        
        self.init()
        self.lat = aDecoder.decodeObject(forKey: "lat") as? Double
        self.lon = aDecoder.decodeObject(forKey: "lon") as? Double
        
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(lat, forKey: "lat")
        aCoder.encode(lon, forKey: "lon")
    }
}

class Route:NSObject, NSCoding {
    
    var ID: Int? = 0
    var Images: [UIImage] = []
    var ImagesPositions: [Point] = []
    var Positions: [Point] = []
    var Altitudes: [Double] = []
    
    override init() {
        
    }
    
    var Positions_in_CLLocationCoordinate2D: [CLLocationCoordinate2D] {
        
        get {
            var positions: [CLLocationCoordinate2D] = []
            for pos in self.Positions {
                positions.append(CLLocationCoordinate2D(latitude: CLLocationDegrees(pos.lat!), longitude: CLLocationDegrees(pos.lon!)))
            }
            return positions
        }
    }
    
    var ImagesPositions_in_CLLocationCoordinate2D: [CLLocationCoordinate2D] {
        
        get {
            var positions: [CLLocationCoordinate2D] = []
            for pos in self.ImagesPositions {
                positions.append(CLLocationCoordinate2D(latitude: CLLocationDegrees(pos.lat!), longitude: CLLocationDegrees(pos.lon!)))
            }
            return positions
        }
    }
    
    public func toCLLocationCoordinate2D(point:Point) ->CLLocationCoordinate2D {
        
        let newPoint = CLLocationCoordinate2D(latitude: CLLocationDegrees(point.lat!), longitude: CLLocationDegrees(point.lon!))
        
        return newPoint
        
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        
        self.init()
        self.ID = aDecoder.decodeObject(forKey: "id") as? Int
        self.Images = aDecoder.decodeObject(forKey: "images") as! [UIImage]
        self.ImagesPositions = aDecoder.decodeObject(forKey: "imagespositions") as! [Point]
        self.Positions = aDecoder.decodeObject(forKey: "positions") as! [Point]
        self.Altitudes = aDecoder.decodeObject(forKey: "altitudes") as! [Double]

    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(ID, forKey: "id")
        aCoder.encode(Images, forKey: "images")
        aCoder.encode(ImagesPositions, forKey: "imagespositions")
        aCoder.encode(Positions, forKey: "positions")
        aCoder.encode(Altitudes, forKey: "altitudes")
    }

}
