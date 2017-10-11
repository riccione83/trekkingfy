//
//  Route.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 20/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

extension Date {
    
    func to_string() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy hh:mm" //Your New Date format as per requirement change it own
        let newDate = dateFormatter.string(from: self) //pass Date here
        return newDate //New formatted Date string
    }
}

class Point {
    
     var lat:Double = 0.0
     var lon:Double = 0.0
    
    convenience init(val:CLLocationCoordinate2D) {
        self.init()
        self.lat = val.latitude
        self.lon = val.longitude
    }
}


class DataPoint: Object {
    
    dynamic var lat:Double = 0.0
    dynamic var lon:Double = 0.0
    
    func toPoint() -> Point {
        let v:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: self.lat, longitude: self.lon)
        return Point(val: v)
    }
    
    convenience init(lat:Double,lon:Double) {  //val:CLLocationCoordinate2D) {
        self.init()
        self.lat = lat
        self.lon = lon
    }
}

class DataImage: Object {
    
    dynamic var data:NSData = NSData()
    
    convenience init(data:NSData) {
        self.init()
        self.data = data
    }
}

class DataAltitude: Object {
    
    dynamic var altitude:Double = 0.0
    
    convenience init(altitude:Double) {
        self.init()
        self.altitude = altitude
    }
}

class DataText: Object {
    
    dynamic var text = ""
    
    convenience init(text:String) {
        self.init()
        self.text = text
    }
}

class Route: Object {
    
    dynamic var ID = -1
    dynamic var Name = ""
    var Images = List<DataImage>()
    var ImagesPositions = List<DataPoint>()
    var ImageDescriptions = List<DataText>()
    var Positions = List<DataPoint>()
    var Altitudes =  List<DataAltitude>()
    dynamic var createdAt =  Date()

    override static func primaryKey() -> String? {
        return "ID"
    }
 
    
    var Positions_in_CLLocationCoordinate2D: [CLLocationCoordinate2D] {
        
        get {
            var positions: [CLLocationCoordinate2D] = []
            for pos in self.Positions {
                positions.append(CLLocationCoordinate2D(latitude: CLLocationDegrees(pos.lat), longitude: CLLocationDegrees(pos.lon)))
            }
            return positions
        }
    }
    
    var ImagesPositions_in_CLLocationCoordinate2D: [CLLocationCoordinate2D] {
        
        get {
            var positions: [CLLocationCoordinate2D] = []
            for pos in self.ImagesPositions {
                positions.append(CLLocationCoordinate2D(latitude: CLLocationDegrees(pos.lat), longitude: CLLocationDegrees(pos.lon)))
            }
            return positions
        }
    }
    
    public func toCLLocationCoordinate2D(point:Point) ->CLLocationCoordinate2D {
        
        let newPoint = CLLocationCoordinate2D(latitude: CLLocationDegrees(point.lat), longitude: CLLocationDegrees(point.lon))
        
        return newPoint
        
    }
    
}
