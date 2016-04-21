//
//  NSManagedObject+LGExtension.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData

public enum LGContentWeight: Int {
    case Stub
    case Light
    case Full
}

protocol LGContentEntityType {
    
    var guid: String? { get }
    var contentWeight: LGContentWeight { get set }

    func updateForPayloadWeight(weight: LGContentWeight)
    func markAs(permanent permanent: Bool, context: NSManagedObjectContext)
    func shouldUpdateDataForWeight(weight: LGContentWeight, payloadDict: [String : AnyObject]) -> Bool
    
}

extension NSManagedObject: LGContextTransferable {
    
    public func transferredToContext(context: NSManagedObjectContext) -> NSManagedObject {
        return context.objectWithID(self.objectID)
    }
    
}

extension NSManagedObject {
    
    public func lg_mergeWithDictionary(dictionary: [String : AnyObject]) {
        if !lg_isUpdateDictionaryValid(dictionary) { return }

        let mappings = self.dynamicType.lg_payloadToEntityMappings()
        let attributes = self.entity.attributesByName
        let dateFormatter = self.dynamicType.lg_dateFormatter()
        
        for (key, rawValue) in dictionary {
            let attributeKey: String
            if let mappingsAttributeKey = mappings[key] {
                attributeKey = mappingsAttributeKey
            }
            else if attributes[key] != nil {
                attributeKey = key
            }
            else {
                continue
            }
            
            if rawValue is NSNull { continue }
            
            let value = lg_transformedValue(rawValue, key: key, attributes: attributes, dateFormatter: dateFormatter)
            self.setValue(value, forKey: attributeKey)
        }
    }
    
    public func lg_transformedValue(rawValue: AnyObject, key: String, attributes: [String : NSAttributeDescription], dateFormatter: NSDateFormatter) -> AnyObject? {
        guard let attributeDescription = attributes[key] else { return rawValue }
        let attributeType = attributeDescription.attributeType;
        
        guard let stringValue = rawValue as? String else { return rawValue }
        
        let intAttributeTypes: [NSAttributeType] = [.Integer64AttributeType, .Integer32AttributeType, .Integer64AttributeType]
        
        if attributeType == .DateAttributeType {
            return dateFormatter.dateFromString(stringValue)
        }
        else if intAttributeTypes.contains(attributeType) {
            return Int(stringValue)
        }
        else if attributeType == .DecimalAttributeType {
            return Double(stringValue)
        }
        else if attributeType == .FloatAttributeType {
            return Float(stringValue)
        }
        else if attributeType == .DoubleAttributeType {
            return Double(stringValue)
        }
    
        return rawValue
    }
    
    public func lg_isUpdateDictionaryValid(dictionary: [String : AnyObject]) -> Bool {
        return true
    }
    
    class func lg_payloadToEntityMappings() -> [String : String] {
        return [String : String]()
    }
    
    class func lg_dateFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        return dateFormatter
    }
    
    class func lg_entityName() -> String {
        print("Entity name needs to be provided in a subclass override")
        abort()
    }
    
    class func lg_mergeObjects<T where T: NSManagedObject, T: LGContentEntityType>(
        payload payload: [[String : AnyObject]],
                payloadGuidKey: String = "objectId",
                objectGuidKey: String = "guid",
                weight: LGContentWeight,
                permanent: Bool = true,
                context: NSManagedObjectContext) -> [T] {
        let guids = payload.map { (dictionary: [String : AnyObject]) -> String in
            dictionary[payloadGuidKey] as! String
        }
        
        let objects: [T] = context.lg_existingObjectsOrStubs(guids: guids, guidKey: objectGuidKey)
        
        let objectsById = objects.lg_indexedByKeyPath(objectGuidKey)
        
        for dictionary in payload {
            let guid = dictionary[payloadGuidKey] as! String
            let object = objectsById[guid]!
            
            if object.shouldUpdateDataForWeight(weight, payloadDict: dictionary) {
                self.lg_parsePayloadForObject(object, payloadDict: dictionary, context: context)
                object.updateForPayloadWeight(weight)
            }
            
            object.markAs(permanent: permanent, context: context)
        }
        
        return objects
    }
    
    class func lg_mergeAndTruncateObjects<T where T: NSManagedObject, T: LGContentEntityType>(
        payload payload: [[String : AnyObject]],
                payloadGuidKey: String = "objectId",
                objectGuidKey: String = "guid",
                weight: LGContentWeight,
                permanent: Bool = true,
                context: NSManagedObjectContext) -> [T] {
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
            
            if object.shouldUpdateDataForWeight(weight, payloadDict: payloadDict) {
                self.lg_parsePayloadForObject(object, payloadDict: payloadDict, context: context)
                object.updateForPayloadWeight(weight)
            }
            
            object.markAs(permanent: permanent, context: context)
            
            resultObjects.append(object)
        }
        
        for (_, object) in objectsByGuid {
            context.deleteObject(object)
        }
        
        return resultObjects
    }
    
    
    class func lg_parsePayloadForObject<T: NSManagedObject>(object: T, payloadDict: [String : AnyObject], context: NSManagedObjectContext) {
        object.lg_mergeWithDictionary(payloadDict)
        //Subclasses may override this method to perform additional parsing, like handle relationship objects
    }
    
    class func lg_objectWithId<T: NSManagedObject>(guid: String, weight: LGContentWeight = .Full, context: NSManagedObjectContext) -> T? {
        let fetchRequest = NSFetchRequest(entityName: T.lg_entityName())
        let predicate = NSPredicate(format: "guid == %@ && weight >= %ld", guid, weight.rawValue)
        fetchRequest.predicate = predicate
        
        let object = try! context.executeFetchRequest(fetchRequest).first as? T
        
        return object
    }
    
}
