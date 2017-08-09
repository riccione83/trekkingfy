//
//  Tools.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 08/08/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}
