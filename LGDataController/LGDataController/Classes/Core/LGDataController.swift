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
    var activeUpdates: [String : AnyObject]
    var updateInfoCache: [String : LGUpdateInfo]
    
    //MARK: - Init
    
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
    
    //MARK: - Main
    
    
    
    //MARK: - Cache Invalidation
    
    func isDataStale(reqestId requestId: String, staleInterval: Double) -> Bool {
        let lastUpdateDate = self.updateInfoForRequestId(requestId).updateDate
        let lastUpdateInterval = lastUpdateDate.timeIntervalSinceReferenceDate
        let staleAtInterval = lastUpdateInterval + staleInterval
        let currentTimeInterval = NSDate().timeIntervalSinceReferenceDate
        let dataValidForInterval = staleAtInterval - currentTimeInterval
        
        let isDataStale = lastUpdateDate.dateByAddingTimeInterval(staleInterval).compare(NSDate()) != .OrderedDescending
        
        #if DEBUG
            if !isDataStale {
                print("Not updating because data is not stale. Stale interval is set to \(staleInterval) second(s). Last update was at \(lastUpdateDate) so data is valid for another \(ceil(dataValidForInterval)) second(s).")
            }
        #endif
        
        return isDataStale
    }
    
    func isDataNew(reqestId requestId: String, response: LGResponse) -> Bool {
        if response.eTag == nil && response.lastModified == nil {
            #if DEBUG
                NSLog("No response etag or last modified for request with id: '\(requestId)', url: '\(response.httpResponse.URL?.absoluteString)'. Request needs to have a fingerprint (e.g. ETag or Last-Modified) for caching.")
            #endif
            return true
        }

        let updateInfo = updateInfoForRequestId(requestId)
        
        if updateInfo.eTag == nil && updateInfo.lastModified == nil {
            #if DEBUG
                print("First time data request with request id: '\(requestId)'");
            #endif
            return true
        }

        var isDataNew: Bool = true
        
        if let responseETag = response.eTag, updateInfoETag = updateInfo.eTag {
            isDataNew = responseETag != updateInfoETag
        }
        else if let responseLastModified = response.lastModified, updateInfoLastModified = updateInfo.lastModified {
            isDataNew = responseLastModified != updateInfoLastModified
        }
            
        #if DEBUG
            NSLog("Data is \(isDataNew ? "" : "NOT ")new for this request.");
        #endif
        
        return isDataNew
    }
    
    //MARK: - Update Info
    
    func refreshUpdateInfo(reqestId requestId: String, response: LGResponse) -> LGUpdateInfo {
        let updateInfo = self.updateInfoForRequestId(requestId)
        updateInfo.eTag = response.eTag
        updateInfo.lastModified = response.lastModified
        return updateInfo
    }
    
    func updateInfoForRequestId(requestId: String) -> LGUpdateInfo {
        if let updateInfo = self.updateInfoCache[requestId] {
            return updateInfo
        }
        
        let newUpdateInfo = LGUpdateInfo(requestId: requestId)
        self.updateInfoCache[requestId] = newUpdateInfo
        return newUpdateInfo
    }
    
    //MARK: - Response
    
    func isResponseValid(response: LGResponse) -> Bool {
        return true
    }
    
    func serializedResponse(response: LGResponse) -> AnyObject? {
        return try? NSJSONSerialization.JSONObjectWithData(response.responseData, options: [])
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
    
    //MARK: - Request Convenience
    
    func createRequest(requestId requestId: String, url: String, methodName: String, parameters: [String : AnyObject]?) -> NSURLRequest {
        var completeUrl = url
        
        if parameters != nil && methodName == "GET" {
            let paramsString = self.queryStringFromParameters(parameters!)
            if paramsString != nil {
                completeUrl.appendContentsOf("?\(paramsString!)")
            }
        }
        
        guard let requestURL = NSURL(string: completeUrl) else { return NSURLRequest() }
        
        let request = NSMutableURLRequest(URL: requestURL)
        request.HTTPMethod = methodName
        
        if parameters != nil && methodName == "POST" {
            let parametersData = try? NSJSONSerialization.dataWithJSONObject(parameters!, options: [])
            request.HTTPBody = parametersData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if methodName == "GET" {
            let updateInfo = self.updateInfoForRequestId(requestId)
            if let eTag = updateInfo.eTag {
                request.setValue(eTag, forHTTPHeaderField: "If-None-Match")
            }
            if let lastModified = updateInfo.lastModified {
                request.setValue(lastModified, forHTTPHeaderField: "Last-Modified")
            }
        }
        
        return request
    }
    
    func queryStringFromParameters(parameters: [String : AnyObject]) -> String? {
        if parameters.count == 0 { return nil }
        
        var query = ""
        
        for (key, value) in parameters {
            query += "&\(key)=\(value)"
        }
        
        return query.substringFromIndex(query.startIndex.advancedBy(1))
    }
    
    //MARK: -
    
}