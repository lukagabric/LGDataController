//
//  NSArray+DataControllerExtension.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData

extension Array: ContextTransferableType {

    public func transferredToContext(context: NSManagedObjectContext) -> [Element] {
        return self.map { ($0 as! NSManagedObject).transferredToContext(context) as! Element }
    }
    
}

extension Array where Element: NSObject {
    
    public func lg_indexedByKeyPath(keyPath: String) -> [String : Element] {
        var dictionary = [String : Element]()

        for element in self {
            guard let key = element.valueForKeyPath(keyPath) as? String else {
                continue
            }
         
            dictionary[key] = element
        }
        
        return dictionary
    }
    
}
