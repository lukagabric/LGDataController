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

public class Dependencies: ContactsDependencies, HomeDependencies {
    
    //MARK: - Vars
    
    public var application: UIApplication {
        return UIApplication.sharedApplication()
    }
    
    public var cacheController: CacheControllerType!
    public let reachabilityService: ReachabilityService

    lazy public var urlSession: NSURLSession = {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfiguration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        sessionConfiguration.timeoutIntervalForRequest = 10
        sessionConfiguration.timeoutIntervalForResource = 10
        sessionConfiguration.HTTPAdditionalHeaders = [
            "X-Parse-Application-Id" : "kS07SE0oFWuckkykW38FN9vdagFZFd5gMsreUzg1",
            "X-Parse-REST-API-Key" : "woMheRmrU3cz4WzYfT6enRCKuIiFrn9dBFn7usCj"
        ]
        
        return NSURLSession(configuration: sessionConfiguration)
    }()
    
    lazy public var dataController: DataController = {
        return LGDataController(session: self.urlSession, mainContext: self.mainContext)
    }()

    public let navigationController: UINavigationController

    public var navigationService: NavigationService!

    public var homeNavigationService: HomeNavigationServiceType {
        return self.navigationService
    }
    
    public var contactsNavigationService: ContactsNavigationServiceType {
        return self.navigationService
    }
    
    public var contactsDataService: ContactsDataService {
        return ContactsDataService(dependencies: self)
    }
    
    public var notificationCenter: NSNotificationCenter {
        return NSNotificationCenter.defaultCenter()
    }
    
    public var mainScreen: UIScreen {
        return UIScreen.mainScreen()
    }
    
    private lazy var rootContext: NSManagedObjectContext = {
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
            print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }

        var managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    private lazy var mainContext: NSManagedObjectContext = {
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.parentContext = self.rootContext
        return managedObjectContext
    }()
    
    //MARK: - Init
    
    init(navigationController: UINavigationController) {
        self.reachabilityService = ReachabilityService()
        self.navigationController = navigationController
        self.navigationService = NavigationService(dependencies: self)
        self.cacheController = LGCacheController(application: self.application, context: self.mainContext)
    }
    
    //MARK: -
    
}
