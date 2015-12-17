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
    
    func registerPurgeBackgroundTask()
    
}

public class LGCacheController: NSObject, CacheControllerType {
    
    let context: NSManagedObjectContext
    let notificationCenter: NSNotificationCenter
    let application: UIApplication
    var backgroundTask: UIBackgroundTaskIdentifier!
    
    init(application: UIApplication, context: NSManagedObjectContext, notificationCenter: NSNotificationCenter) {
        self.application = application
        self.context = context
        self.notificationCenter = notificationCenter

        super.init()
        
        self.configureNotifications()
    }
    
    func configureNotifications() {
        self.notificationCenter.addObserver(self, selector: "registerPurgeBackgroundTask", name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }

    public func registerPurgeBackgroundTask() {
        self.backgroundTask = self.application.beginBackgroundTaskWithExpirationHandler {
            [unowned self] in
            self.endBackgroundTask()
        }
        
        assert(self.backgroundTask != UIBackgroundTaskInvalid, "Background task is invalid!")
        
        self.purgeSessionContentEntities()
        self.endBackgroundTask()
    }
    
    func purgeSessionContentEntities() {
        let sessionEntity = SessionEntity.sessionEntityInContext(self.context)
        if let sessionEntities = sessionEntity.contentEntity {
            for entity in sessionEntities {
                let entity = entity as! ContentEntity
                self.context.deleteObject(entity)
            }
        }
    }
    
    func endBackgroundTask() {
        self.application.endBackgroundTask(self.backgroundTask)
        self.backgroundTask = UIBackgroundTaskInvalid
    }
    
}
