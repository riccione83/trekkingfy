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
    
    private let kCurrentDatabaseVersion = 2
    private var database:Realm
    static let sharedInstance = DBManager()
    
    private init() {
        
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 2,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                        migration.enumerateObjects(ofType: Route.className()) { (_, newRoute) in
                            newRoute?["Name"] = "Route".localized
                        }
                }
        })
        Realm.Configuration.defaultConfiguration = config
    
        _ = try! Realm.performMigration()
        
        database = try! Realm()
    }
    
    func getNewID() -> Int {
        
        let items = getDataFromDB()
        let newId = items.map { $0.ID }.max()
        if items.count == 0 {
            return 0
        }
        else {
            return newId!
        }
    }
    
    func getDataFromDB() -> Results<Route> {
        
        let results: Results<Route> = database.objects(Route.self)
        return results
    }
    
    func addData(object: Route) {
        
        try! database.write {
            database.add(object, update: false)
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
