//
//  NSManagedObject+LGExtension.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject: LGContextTransferable {
    
    func transferredToContext(context: NSManagedObjectContext) -> NSManagedObject {
        return context.objectWithID(self.objectID)
    }
    
}
