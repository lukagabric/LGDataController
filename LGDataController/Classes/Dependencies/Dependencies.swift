//
//  Dependencies.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import UIKit
import CoreData

public class Dependencies: ContactsModuleDependencies, HomeModuleDependencies {
    
    //MARK: - Dependencies
    
    private lazy var urlSession: NSURLSession = {
        return NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    }()
    
    public lazy var dataController: DataController = {
        return LGDataController(session: self.urlSession, mainContext: self.managedObjectContext)
    }()
    
    public lazy var navigationService: NavigationService = {
        return NavigationService(dependencies: self)
    }()
    
    public var homeNavigationService: HomeNavigationService {
        return self.navigationService
    }
    
    private lazy var managedObjectContext: NSManagedObjectContext = {
        let modelURL = NSBundle.mainBundle().URLForResource("LGDataController", withExtension: "mom")!
        let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL)!
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let url = urls[urls.count-1].URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }

        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    //MARK: -
    
}