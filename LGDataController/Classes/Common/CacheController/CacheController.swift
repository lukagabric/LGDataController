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

public class CacheController: NSObject {
    
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
        
        let fetchRequest = NSFetchRequest(entityName: ContentEntity.lg_entityName())
        fetchRequest.predicate = NSPredicate(format: "permanent == false")
        let sessionEntities = try! self.context.executeFetchRequest(fetchRequest) as! [ContentEntity]
        
        for entity in sessionEntities {
            self.context.deleteObject(entity)
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
