//
//  RealmManager.swift
//  RealmDemo
//
//  Created by Hisen on 2017/7/1.
//  Copyright © 2017年 Hisen. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class RealmManager: NSObject {
    
    static let sharedRealmManager = RealmManager()
        
    private override init() {
        super.init()
    }
    
    func configDB(name dbName: String) -> String {
        
        var config = Realm.Configuration()        
        // Use the default directory, but replace the filename with the username
        config.fileURL = config.fileURL!.deletingLastPathComponent()
            .appendingPathComponent("\(dbName).realm")
        config.readOnly = false
        let currentVersion = UInt64(1.0)
        config.schemaVersion = currentVersion
        config.migrationBlock = { migration, oldSchemaVersion in
            if (oldSchemaVersion < currentVersion) {
                print("need to update")
            }
        }
        // Set this as the configuration used for the default Realm
        Realm.Configuration.defaultConfiguration = config
        return (config.fileURL?.path)!
    }
}
