//
//  NSArray+LGExtension.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData

extension Array: LGContextTransferable {

    func transferredToContext(context: NSManagedObjectContext) -> [NSManagedObject] {
        return self.filter{$0 is NSManagedObject}.map{($0 as! NSManagedObject).transferredToContext(context)}
    }
    
}

extension Array where Element: NSObject {
    
    func lg_indexedByKeyPath(keyPath: String) -> [String : Element] {
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
