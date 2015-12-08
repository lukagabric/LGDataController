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

typealias LGActionClosure = () -> ()

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
    
    func updateData<T where T: LGContextTransferable>(
        url url: String,
        methodName: String,
        parameters: [String : AnyObject]?,
        requestId: String,
        staleInterval: NSTimeInterval,
        dataUpdate: (data: AnyObject, response: LGResponse, context: NSManagedObjectContext) -> T) -> Signal<T, NSError>? {
            assert(NSThread.currentThread().isMainThread, "Must be called on main thread")
            
            if let update = self.activeUpdates[requestId] {
                return update as? Signal<T, NSError>
            }
            
            if !self.isDataStale(reqestId: requestId, staleInterval: staleInterval) { return nil }
            
            guard let request = self.createRequest(requestId: requestId, url: url, methodName: methodName, parameters: parameters) else { return  nil }

            let operation = LGRequestOperation(session: self.session, request: request)
            self.dataDownloadQueue.addOperation(operation)
            
            let dataUpdateSignal = operation.signal.flatMap(FlattenStrategy.Latest) { response -> Signal<T, NSError> in
                let (signal, observer) = Signal<T, NSError>.pipe()

                if let error = self.validateResponse(response) {
                    observer.sendFailed(error)
                    return signal
                }
                
                if !self.isDataNew(reqestId: requestId, response: response) {
                    self.refreshUpdateInfo(reqestId: requestId, response: response)
                    observer.sendCompleted()
                    return signal
                }
                
                guard let serializedResponse = self.serializedResponse(response) else {
                    observer.sendFailed(NSError(domain: "Unable to serialize data", code: 0, userInfo: nil))
                    return signal
                }
                
                self.bgContext.performBlock {
                    let resultData = dataUpdate(data: serializedResponse, response: response, context: self.bgContext)
                    
                    self.saveDataToPersistentStore(context: self.bgContext) {
                        self.refreshUpdateInfo(reqestId: requestId, response: response)
                        
                        let mainContextResults = resultData.transferredToContext(self.mainContext) as! T
                        
                        observer.sendNext(mainContextResults)
                        observer.sendCompleted()
                    }
                }
                
                return signal
            }
            
            return dataUpdateSignal.takeLast(1).observeOn(QueueScheduler.mainQueueScheduler)
    }
    
    public func refreshSignal<T>(inputSignal inputSignal: Signal<T, NSError>?) -> Signal<Void, NSError>? {
        return inputSignal?.map { _ in () }
    }
    
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
        updateInfo.updateDate = NSDate()
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
    
    func validateResponse(response: LGResponse) -> NSError? {
        return nil
    }
    
    func serializedResponse(response: LGResponse) -> AnyObject? {
        return try? NSJSONSerialization.JSONObjectWithData(response.responseData, options: [])
    }
    
    //MARK: - Save
    
    func saveDataToPersistentStore(context context: NSManagedObjectContext, completion: LGActionClosure?) {
        context.performBlock { [weak self] in
            guard let strongSelf = self else { return }
            
            try! context.save()
            
            if context.parentContext != nil {
                strongSelf.saveDataToPersistentStore(context: context.parentContext!, completion: completion)
            }
            else {
                if completion != nil {
                    dispatch_async(dispatch_get_main_queue(), completion!)
                }
            }
        }
    }
    
    //MARK: - Request Convenience
    
    func createRequest(requestId requestId: String, url: String, methodName: String, parameters: [String : AnyObject]?) -> NSURLRequest? {
        var completeUrl = url
        
        if parameters != nil && methodName == "GET" {
            let paramsString = self.queryStringFromParameters(parameters!)
            if paramsString != nil {
                completeUrl.appendContentsOf("?\(paramsString!)")
            }
        }
        
        guard let requestURL = NSURL(string: completeUrl) else { return nil }
        
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