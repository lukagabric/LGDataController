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
    
    public func lg_existingObjectOrStub<T: NSManagedObject>(guid guid: String, guidKey: String) -> T {
        let entityName = T.lg_entityName()
        assert(!entityName.isEmpty, "Entity name must be specified")
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", guidKey, guid)

        let existingObjects: [T] = try! self.executeFetchRequest(fetchRequest) as! [T]
        
        let object: T
        if let entity = existingObjects.first {
            object = entity
        }
        else {
            let newObject = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self)
            newObject.setValue(guid, forKey: guidKey)
            object = newObject as! T
        }
        
        return object
    }
    
    public func lg_existingObjectsOrStubs<T: NSManagedObject>(guids guids: [String], guidKey: String) -> ([T], NSError?) {
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
    
    public func lg_existingObjectsOrStubs<T: NSManagedObject>(guids guids: [String], guidKey: String) -> [T] {
        return self.lg_existingObjectsOrStubs(guids: guids, guidKey: guidKey).0
    }
    
    public func lg_allObjects<T: NSManagedObject>() -> ([T], NSError?) {
        let entityName = T.lg_entityName()
        if entityName.isEmpty { return ([T](), NSError(domain: "Entity name must be specified", code: 0, userInfo: nil)) }
        assert(!entityName.isEmpty, "Entity name must be specified")
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        let existingObjects: [T]
        
        do {
            existingObjects = try self.executeFetchRequest(fetchRequest) as! [T]
        }
        catch let error as NSError {
            return ([], error)
        }
        
        return (existingObjects, nil)
    }
    
    public func lg_allObjects<T: NSManagedObject>() -> [T] {
        return self.lg_allObjects().0
    }
    
    public func lg_saveToPersistentStore(completion: (() -> ())?) {
        self.lg_saveContextToPersistentStore(context: self, completion: completion)
    }
    
    private func lg_saveContextToPersistentStore(context context: NSManagedObjectContext, completion: (() -> ())?) {
        context.performBlock { [weak self] in
            guard let strongSelf = self else { return }
            
            try! context.save()
            
            if context.parentContext != nil {
                strongSelf.lg_saveContextToPersistentStore(context: context.parentContext!, completion: completion)
            }
            else {
                if completion != nil {
                    dispatch_async(dispatch_get_main_queue(), completion!)
                }
            }
        }
    }

}
