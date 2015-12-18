//
//  PermanentEntity.swift
//  LGDataController
//
//  Created by Luka Gabric on 17/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData

public class PermanentEntity: NSManagedObject {
    
    //MARK: - Entity Name
    
    override class func lg_entityName() -> String {
        return "PermanentEntity"
    }
    
    //MARK: - Getter
    
    class func permanentEntityInContext(context: NSManagedObjectContext) -> PermanentEntity {
        let permanentEntityArray: [PermanentEntity] = context.lg_allObjects()
        assert(permanentEntityArray.count < 2, "Must not contain more than 1 object")
        
        let permanentEntity: PermanentEntity
        if let entity = permanentEntityArray.first {
            permanentEntity = entity
        }
        else {
            permanentEntity = NSEntityDescription.insertNewObjectForEntityForName(PermanentEntity.lg_entityName(), inManagedObjectContext: context) as! PermanentEntity
        }
        
        return permanentEntity
    }
    
    //MARK: -
    
}
