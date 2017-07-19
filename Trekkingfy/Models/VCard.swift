//
//  VCard.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 19/07/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import Foundation
import MapKit

class VCard {

class func vCardURL(from coordinate: CLLocationCoordinate2D, with name: String?) -> URL {
    
    let vCardFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("vCard.loc.vcf")
    
    let vCardString = [
        "BEGIN:VCARD",
        "VERSION:4.0",
        "FN:\(name ?? "Shared Location")",
        "item1.URL;type=pref:http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)",
        "item1.X-ABLabel:map url",
        "END:VCARD"
        ].joined(separator: "\n")
    
    do {
        try vCardString.write(toFile: vCardFileURL.path, atomically: true, encoding: .utf8)
    } catch let error {
        print("Error, \(error.localizedDescription), saving vCard: \(vCardString) to file path: \(vCardFileURL.path).")
    }
    
    return vCardFileURL
}
}
