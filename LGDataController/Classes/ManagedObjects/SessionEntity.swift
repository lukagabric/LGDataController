//
//  SessionEntity.swift
//  LGDataController
//
//  Created by Luka Gabric on 17/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData

class SessionEntity: NSManagedObject {

    //MARK: - Entity Name
    
    override class func lg_entityName() -> String {
        return "SessionEntity"
    }
    
    //MARK: - Getter
    
    class func sessionEntityInContext(context: NSManagedObjectContext) -> SessionEntity {
        let sessionEntityArray: [SessionEntity] = context.lg_allObjects()
        assert(sessionEntityArray.count < 2, "Must not contain more than 1 object")

        let sessionEntity: SessionEntity
        if let entity = sessionEntityArray.first {
            sessionEntity = entity
        }
        else {
            sessionEntity = NSEntityDescription.insertNewObjectForEntityForName(SessionEntity.lg_entityName(), inManagedObjectContext: context) as! SessionEntity
        }
        
        return sessionEntity
    }
    
    //MARK: -

}
