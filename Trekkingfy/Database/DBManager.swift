//
//  DBManager.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 10/07/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import Foundation
import RealmSwift

class DBManager {
    
    private var database:Realm
    static let sharedInstance = DBManager()
    
    private init() {
        
        database = try! Realm()
        
    }
    
    func getDataFromDB() -> Results<Route> {
        
        let results: Results<Route> = database.objects(Route.self)
        return results
    }
    
    func addData(object: Route) {
        
        try! database.write {
            database.add(object, update: true)
            print("Added new object")
        }
    }
    
    func deleteAllDatabase()  {
        try! database.write {
            database.deleteAll()
        }
    }
    
    func deleteFromDb(object: Route) {
        
        try! database.write {
            
            database.delete(object)
        }
    }
    
}
