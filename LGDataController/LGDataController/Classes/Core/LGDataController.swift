//
//  LGDataController.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa
import CoreData

typealias ActionClosure = () -> ()

public class LGDataController {
    
    let session: NSURLSession
    let mainContext: NSManagedObjectContext
    let bgContext: NSManagedObjectContext
    let dataDownloadQueue: NSOperationQueue
    let activeUpdates: [String : AnyObject]
    let updateInfoCache: [String : LGUpdateInfo]
    
    init(session: NSURLSession, mainContext: NSManagedObjectContext) {
        self.session = session
        self.mainContext = mainContext
        
        self.bgContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.bgContext.parentContext = self.mainContext
        
        self.dataDownloadQueue = NSOperationQueue()
        self.dataDownloadQueue.maxConcurrentOperationCount = 1

        self.updateInfoCache = [String : LGUpdateInfo]()
        
        self.activeUpdates = [String : AnyObject]()
    }
    
    
    //MARK: - Save
    
    func saveData(completion: ActionClosure?) {
        try! self.bgContext.save()
        
        self.mainContext.performBlockAndWait {
            try! self.mainContext.save()
            
            completion?()
            
            let rootContext = self.mainContext.parentContext
            rootContext?.performBlock {
                try! rootContext?.save()
            }
        }
    }
    
    //MARK: -
    
}