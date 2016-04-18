//
//  LGCacheController.swift
//  LGDataController
//
//  Created by Luka Gabric on 17/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData
import UIKit

public protocol CacheControllerType {
    
    func purgeSessionContentEntities(completion: (() -> Void)?)
    
}

public class LGCacheController: NSObject, CacheControllerType {
    
    let context: NSManagedObjectContext
    let application: UIApplication
    var backgroundTask: UIBackgroundTaskIdentifier!
    
    init(application: UIApplication, context: NSManagedObjectContext) {
        self.application = application
        self.context = context

        super.init()
    }
    
    public func purgeSessionContentEntities(completion: (() -> Void)?) {
        self.backgroundTask = self.application.beginBackgroundTaskWithExpirationHandler {
            [unowned self] in
            self.endBackgroundTask()
        }
        
        assert(self.backgroundTask != UIBackgroundTaskInvalid, "Background task is invalid!")
        
        let sessionEntity = SessionEntity.sessionEntityInContext(self.context)
        if let sessionEntities = sessionEntity.contentEntity {
            for entity in sessionEntities {
                let entity = entity as! ContentEntity
                self.context.deleteObject(entity)
            }
        }
        
        self.context.lg_saveToPersistentStore { 
            self.endBackgroundTask()
            
            if completion != nil { completion!() }
        }
        
    }
    
    func endBackgroundTask() {
        self.application.endBackgroundTask(self.backgroundTask)
        self.backgroundTask = UIBackgroundTaskInvalid
    }
    
}
