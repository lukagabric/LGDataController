//
//  LGParsing.swift
//  LGDataController
//
//  Created by Luka Gabric on 22/04/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData

let defaultPayloadGuidKey = "objectId"
let defaultObjectGuidKey = "guid"

class LGParsing {
    
    //MARK: - Merge Array Of Objects With Payload Dictionaries
    
    class func lg_mergeObjects<T where T: NSManagedObject, T: LGContentEntityType>(
        payload payload: [[String : AnyObject]],
                payloadGuidKey: String = defaultPayloadGuidKey,
                objectGuidKey: String = defaultObjectGuidKey,
                weight: LGContentWeight,
                permanent: Bool = true,
                context: NSManagedObjectContext,
                merge: ((object: T, payloadDict: [String : AnyObject]) -> ())? = nil) -> [T] {
        let guids = payload.map { (dictionary: [String : AnyObject]) -> String in
            dictionary[payloadGuidKey] as! String
        }
        
        let objects: [T] = context.lg_existingObjectsOrStubs(guids: guids, guidKey: objectGuidKey)
        
        let objectsById = objects.lg_indexedByKeyPath(objectGuidKey)
        
        for payloadDict in payload {
            let guid = payloadDict[payloadGuidKey] as! String
            let object = objectsById[guid]!
            
            if object.shouldUpdateData(weight: weight, payloadDict: payloadDict) {
                object.lg_mergeWithDictionary(payloadDict)
                object.updateForPayloadWeight(weight)
                if let merge = merge {
                    merge(object: object, payloadDict: payloadDict)
                }
            }
            
            object.markAs(permanent: permanent, context: context)
        }
        
        return objects
    }
    
    class func lg_mergeAndTruncateObjects<T where T: NSManagedObject, T: LGContentEntityType>(
        payload payload: [[String : AnyObject]],
                payloadGuidKey: String = defaultPayloadGuidKey,
                objectGuidKey: String = defaultObjectGuidKey,
                weight: LGContentWeight,
                permanent: Bool = true,
                context: NSManagedObjectContext,
                merge: ((object: T, payloadDict: [String : AnyObject]) -> ())? = nil) -> [T] {
        let allObjects: [T] = context.lg_allObjects()
        var objectsByGuid: [String : T] = allObjects.lg_indexedByKeyPath(objectGuidKey)
        
        var resultObjects = [T]()
        for payloadDict in payload {
            let guid = payloadDict[payloadGuidKey] as! String
            let object: T
            if let item = objectsByGuid.removeValueForKey(guid) {
                object = item
            }
            else {
                object = NSEntityDescription.insertNewObjectForEntityForName(T.lg_entityName(), inManagedObjectContext: context) as! T
            }
            
            if object.shouldUpdateData(weight: weight, payloadDict: payloadDict) {
                object.lg_mergeWithDictionary(payloadDict)
                object.updateForPayloadWeight(weight)
                if let merge = merge {
                    merge(object: object, payloadDict: payloadDict)
                }
            }
            
            object.markAs(permanent: permanent, context: context)
            
            resultObjects.append(object)
        }
        
        for (_, object) in objectsByGuid {
            context.deleteObject(object)
        }
        
        return resultObjects
    }
    
    //MARK: - 
    
}
