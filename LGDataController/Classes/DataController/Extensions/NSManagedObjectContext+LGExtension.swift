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
    
    //MARK: - Fetch
    
    public func lg_allObjects<T: NSManagedObject>() -> [T] {
        let entityName = T.lg_entityName()
        let fetchRequest = NSFetchRequest(entityName: entityName)
        return try! self.executeFetchRequest(fetchRequest) as! [T]
    }
    
    public func lg_objectWithId<T: NSManagedObject>(guid: String, weight: LGContentWeight = .Full) -> T? {
        let fetchRequest = NSFetchRequest(entityName: T.lg_entityName())
        let predicate = NSPredicate(format: "guid == %@ && weight >= %ld", guid, weight.rawValue)
        fetchRequest.predicate = predicate
        
        return try! self.executeFetchRequest(fetchRequest).first as? T
    }
    
    public func lg_existingObjectOrStub<T: NSManagedObject>(guid guid: String, guidKey: String = defaultObjectGuidKey) -> T {
        let entityName = T.lg_entityName()
        assert(!entityName.isEmpty, "Entity name must be specified")
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", guidKey, guid)

        let existingObjects = try! self.executeFetchRequest(fetchRequest) as! [T]
        
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
    
    public func lg_existingObjectsOrStubs<T: NSManagedObject>(guids guids: [String], guidKey: String = defaultObjectGuidKey) -> [T] {
        let entityName = T.lg_entityName()
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "(%K IN %@)", guidKey, guids)
        
        let existingObjects = try! self.executeFetchRequest(fetchRequest) as! [T]
        
        let existingObjectsGuids = Set(existingObjects.map { ($0 as NSManagedObject).valueForKey(guidKey) as! String })
        let guidsSet = Set(guids)
        let newObjectGuids = guidsSet.subtract(existingObjectsGuids)
        let newObjects = newObjectGuids.map { guid -> T in
            let newObject = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self)
            newObject.setValue(guid, forKey: guidKey)
            return newObject as! T
        }
        
        return newObjects + existingObjects
    }

    public func lg_orderedExistingObjectsOrStubs<T: NSManagedObject>(guids guids: [String], guidKey: String = defaultObjectGuidKey) -> [T] {
        let entityName = T.lg_entityName()
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "(%K IN %@)", guidKey, guids)
        
        let existingObjects = try! self.executeFetchRequest(fetchRequest) as! [T]

        let existingObjectsByGuid = existingObjects.lg_indexedByKeyPath("guid")
        
        var orderedObjects = [T]()
        
        for guid in guids {
            let object: T
            
            if let existingObject = existingObjectsByGuid[guid] {
                object = existingObject
            }
            else {
                let newObject = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self)
                newObject.setValue(guid, forKey: guidKey)
                object = newObject as! T
            }
            
            orderedObjects.append(object)
        }
        
        return orderedObjects
    }
    
    //MARK: - Save
    
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
    
    //MARK: -

}
