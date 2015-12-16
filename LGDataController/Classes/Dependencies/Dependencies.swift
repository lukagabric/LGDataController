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
    
    private let navigationController: UINavigationController
    
    //MARK: - Init
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    //MARK: - Dependencies

    lazy public var urlSession: NSURLSession = {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfiguration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        sessionConfiguration.timeoutIntervalForRequest = 5
        sessionConfiguration.timeoutIntervalForResource = 5
        sessionConfiguration.HTTPAdditionalHeaders = [
            "X-Parse-Application-Id" : "kS07SE0oFWuckkykW38FN9vdagFZFd5gMsreUzg1",
            "X-Parse-REST-API-Key" : "woMheRmrU3cz4WzYfT6enRCKuIiFrn9dBFn7usCj"
        ]
        
        return NSURLSession(configuration: sessionConfiguration)
    }()
    
    lazy public var dataController: DataController = {
        return LGDataController(session: self.urlSession, mainContext: self.managedObjectContext)
    }()
    
    lazy public var navigationService: NavigationService = {
        return NavigationService(dependencies: self, navigationController: self.navigationController)
    }()
    
    public var homeNavigationService: HomeNavigationServiceType {
        return self.navigationService
    }
    
    public var contactsNavigationService: ContactsNavigationServiceType {
        return self.navigationService
    }
    
    lazy public var contactsDataService: ContactsDataServiceType = {
        return ContactsDataService(dataController: self.dataController)
    }()
    
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
