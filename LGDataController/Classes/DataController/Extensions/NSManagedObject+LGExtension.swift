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

public protocol LGContentEntityType {
    
    var guid: String? { get }
    var contentWeight: LGContentWeight { get set }
    
}

extension NSManagedObject: LGContextTransferable {
    
    public func transferredToContext(context: NSManagedObjectContext) -> NSManagedObject {
        return context.objectWithID(self.objectID)
    }
    
}

extension NSManagedObject {
    
    public func lg_mergeWithDictionary(dictionary: [String : AnyObject]) {
        if !lg_isUpdateDictionaryValid(dictionary) { return }

        let mappings = self.dynamicType.lg_responseToEntityMappings()
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
    
    class func lg_responseToEntityMappings() -> [String : String] {
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
    
    class func lg_mergeEntitiesWithPayload<T where T: NSManagedObject, T: LGContentEntityType>(
        payload: [[String : AnyObject]],
        payloadGuidKey: String,
        entityGuidKey: String,
        weight: LGContentWeight,
        context: NSManagedObjectContext) -> [T] {
            let guids = payload.map { (dictionary: [String : AnyObject]) -> String in
                dictionary[payloadGuidKey] as! String
            }
            let entities: [T] = context.lg_existingObjectsOrStubs(guids: guids, guidKey: entityGuidKey)
            
            let entitiesById: [String : T] = entities.lg_indexedByKeyPath(entityGuidKey)
            
            for dictionary in payload {
                let guid = dictionary[payloadGuidKey] as! String
                var entity = entitiesById[guid] as T!
                
                if weight == .Full {
                    entity.contentWeight = .Full
                }
                else if entity.contentWeight != .Full {
                    entity.contentWeight = .Light
                }
                
                entity.lg_mergeWithDictionary(dictionary)
            }
            
            return entities
    }
    
}
