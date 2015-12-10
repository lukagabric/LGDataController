//
//  NSManagedObjectContext+LGExtension.swift
//  LGDataController
//
//  Created by Luka Gabric on 19/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    func lg_existingObjectsOrStubs<T: NSManagedObject>(guids guids: [String], guidKey: String) -> ([T], NSError?) {
        let entityName = T.lg_entityName()
        if entityName.isEmpty { return ([T](), NSError(domain: "Entity name must be specified", code: 0, userInfo: nil)) }
        assert(!entityName.isEmpty, "Entity name must be specified")
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "(%K IN %@)", guidKey, guids)
        
        let existingObjects: [T]
        
        do {
            existingObjects = try self.executeFetchRequest(fetchRequest) as! [T]
        }
        catch let error as NSError {
            return ([], error)
        }
        
        let existingObjectsGuids: [String] = existingObjects.map { ($0 as NSManagedObject).valueForKey(guidKey) as! String }
        let newObjectGuids = guids.filter { guid in !existingObjectsGuids.contains(guid) }
        let newObjects = newObjectGuids.map { (guid: String) -> T in
            let newObject = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self)
            newObject.setValue(guid, forKey: guidKey)
            return newObject as! T
        }
        
        return (newObjects + existingObjects, nil)
    }
    
    func lg_existingObjectsOrStubs<T: NSManagedObject>(guids guids: [String], guidKey: String) -> [T] {
        let tuple: ([T], NSError?) = self.lg_existingObjectsOrStubs(guids: guids, guidKey: guidKey)
        return tuple.0
    }

}
