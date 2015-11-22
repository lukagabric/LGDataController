//
//  NSManagedObject+LGExtension.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData

enum LGContentWeight: Int {
    case Stub
    case Light
    case Full
}

extension NSManagedObject: LGContextTransferable {
    
    func transferredToContext(context: NSManagedObjectContext) -> NSManagedObject {
        return context.objectWithID(self.objectID)
    }
    
}

extension NSManagedObject {
    
    func lg_mergeWithDictionary(dictionary: [String : AnyObject]) {
        if !lg_isUpdateDictionaryValid(dictionary) { return }
        
        let mappings = self.dynamicType.lg_dataUpdateMappings()
        let attributes = self.entity.attributesByName
        let dateFormatter = self.dynamicType.lg_dateFormatter()
        
        for (key, rawValue) in dictionary {
            guard let attributeKey = mappings[key] else { continue }
            if rawValue is NSNull { continue }
            
            let value = lg_transformedValue(rawValue, key: key, attributes: attributes, dateFormatter: dateFormatter)
            self.setValue(value, forKey: attributeKey)
        }
    }
    
    func lg_transformedValue(rawValue: AnyObject, key: String, attributes: [String : NSAttributeDescription], dateFormatter: NSDateFormatter) -> AnyObject? {
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
    
    func lg_isUpdateDictionaryValid(dictionary: [String : AnyObject]) -> Bool {
        return true
    }
    
    class func lg_dataUpdateMappings() -> [String : String] {
        print("Mappings need to be provided in a subclass override")
        abort()
    }
    
    class func lg_dateFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'";
        return dateFormatter
    }
    
    class func lg_entityName() -> String {
        print("Entity name needs to be provided in a subclass override")
        abort()
    }
    
    class func lg_mergeObjects<T: NSManagedObject>(data data: [[String : AnyObject]], dataGuidKey: String, objectGuidKey: String, weight: LGContentWeight, context: NSManagedObjectContext) -> [T] {
        
        let objectsGuids = data.map { (dictionary: [String : AnyObject]) -> String in
            dictionary[dataGuidKey] as! String
        }
        let objects: [T] = context.lg_existingObjectsOrStubs(guids: objectsGuids, guidKey: objectGuidKey)
        
        let objectsById: [String : T] = objects.lg_indexedByKeyPath(objectGuidKey)
        
        for dictionary in data {
            let guid = dictionary[dataGuidKey] as! String
            let object = objectsById[guid] as! NSManagedObject
            object.setValue(weight.rawValue, forKey: "weight")
            object.lg_mergeWithDictionary(dictionary)
        }
        
        return objects
    }
    
}
