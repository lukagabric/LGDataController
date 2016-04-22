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
    
    //MARK: - Parsing Convenience
    
    class func lg_entityName() -> String {
        print("Entity name needs to be provided in a subclass override")
        abort()
    }
    
    class func lg_payloadToEntityMappings() -> [String : String] {
        return [String : String]()
    }
    
    class func lg_dateFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        return dateFormatter
    }
    
    //MARK: - Merge Object with Payload Dictionary
    
    public func lg_mergeWithDictionary(dictionary: [String : AnyObject]) {
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
            
            let value = self.lg_transformedValue(rawValue, key: key, attributes: attributes, dateFormatter: dateFormatter)
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
    
    //MARK: -
        
}
