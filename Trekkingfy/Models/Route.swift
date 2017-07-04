//
//  Route.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 20/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit
import MapKit

extension Date {
    
    func to_string() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/mm/yyyy hh:mm" //Your New Date format as per requirement change it own
        let newDate = dateFormatter.string(from: self) //pass Date here
        return newDate //New formatted Date string
    }
}


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
    var ImageDescriptions: [String]? = []
    var Positions: [Point] = []
    var Altitudes: [Double] = []
    var createdAt: Date? = Date()
    
    override init() {
        self.ID = -1
        super.init()
        
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
        self.ImageDescriptions = (aDecoder.decodeObject(forKey: "imagesdescriptions") as? [String])
        self.createdAt = aDecoder.decodeObject(forKey: "createdAt") as? Date
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(ID, forKey: "id")
        aCoder.encode(Images, forKey: "images")
        aCoder.encode(ImagesPositions, forKey: "imagespositions")
        aCoder.encode(Positions, forKey: "positions")
        aCoder.encode(Altitudes, forKey: "altitudes")
        aCoder.encode(ImageDescriptions, forKey: "imagesdescriptions")
        aCoder.encode(createdAt, forKey: "createAt")
    }

}
