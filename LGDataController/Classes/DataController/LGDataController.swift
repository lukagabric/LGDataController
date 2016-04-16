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

public protocol LGContextTransferable {
    associatedtype TransferredType
    func transferredToContext(context: NSManagedObjectContext) -> TransferredType
}

public class LGUpdateInfo {
    
    var requestId: String
    var eTag: String?
    var lastModified: String?
    var updateDate: NSDate
    
    init(requestId: String) {
        self.requestId = requestId
        self.updateDate = NSDate.distantPast()
    }
    
}

public protocol DataController {
    
    func updateData<T where T: LGContextTransferable>(
        url url: String,
        methodName: String,
        parameters: [String : AnyObject]?,
        requestId: String,
        staleInterval: NSTimeInterval,
        dataUpdate: (payload: Any, response: LGResponse, context: NSManagedObjectContext) -> T?) -> SignalProducer<T?, NSError>?
    
    var mainContext: NSManagedObjectContext { get }
    func deleteObject(object: NSManagedObject)
    
}

public class LGDataController: DataController {
    
    let session: NSURLSession
    public let mainContext: NSManagedObjectContext
    let bgContext: NSManagedObjectContext
    let dataDownloadQueue: NSOperationQueue
    var activeUpdates: [String : Any]
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
        
        self.activeUpdates = [String : Any]()
    }
    
    //MARK: - Main
    
    public func updateData<T where T: LGContextTransferable>(
        url url: String,
        methodName: String,
        parameters: [String : AnyObject]?,
        requestId: String,
        staleInterval: NSTimeInterval,
        dataUpdate: (payload: Any, response: LGResponse, context: NSManagedObjectContext) -> T?) -> SignalProducer<T?, NSError>? {
            assert(NSThread.currentThread().isMainThread, "Must be called on main thread")
            
            if let activeUpdateProducer = self.activeUpdates[requestId] {
                return activeUpdateProducer as? SignalProducer<T?, NSError>
            }
            
            if !self.isDataStale(reqestId: requestId, staleInterval: staleInterval) { return nil }
            
            guard let request = self.createRequest(requestId: requestId, url: url, methodName: methodName, parameters: parameters) else { return  nil }

            let operation = LGRequestOperation(session: self.session, request: request)
            self.dataDownloadQueue.addOperation(operation)
            
            let (updateProducer, updateObserver) = SignalProducer<T?, NSError>.buffer(1)
            
            let operationProducer = operation.producer.takeLast(1)
            operationProducer.startWithNext { response in
                if let error = self.validateResponse(response) {
                    dispatch_async(dispatch_get_main_queue(), {
                        updateObserver.sendFailed(error)
                    })
                    return
                }
                
                if !self.isDataNew(reqestId: requestId, response: response) {
                    self.refreshUpdateInfo(reqestId: requestId, response: response)
                    dispatch_async(dispatch_get_main_queue(), {
                        updateObserver.sendCompleted()
                    })
                    return
                }
                
                guard let serializedResponse = self.serializedResponse(response) else {
                    dispatch_async(dispatch_get_main_queue(), {
                        updateObserver.sendFailed(NSError(domain: "Unable to serialize data", code: 0, userInfo: nil))
                    })
                    return
                }
                
                self.bgContext.performBlock {
                    let resultData = dataUpdate(payload: serializedResponse, response: response, context: self.bgContext)
                    
                    self.saveDataToPersistentStore(context: self.bgContext) {
                        self.refreshUpdateInfo(reqestId: requestId, response: response)
                        
                        let mainContextResults = resultData?.transferredToContext(self.mainContext) as? T
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            updateObserver.sendNext(mainContextResults)
                            updateObserver.sendCompleted()
                        })
                    }
                }
            }
            
            operationProducer.startWithFailed { error in
                dispatch_async(dispatch_get_main_queue(), {
                    updateObserver.sendFailed(error)
                })
            }
            
            let resultProducer = updateProducer.takeLast(1).observeOn(ImmediateScheduler())
            
            resultProducer.start { [weak self] event in
                if event.isTerminating {
                    self?.activeUpdates.removeValueForKey(requestId)
                }
            }
            
            self.activeUpdates[requestId] = resultProducer

            return resultProducer
    }
    
    public func deleteObject(object: NSManagedObject) {
        assert(NSThread.currentThread().isMainThread, "Must be called on main thread")

        self.mainContext.deleteObject(object)
        self.saveDataToPersistentStore(context: self.mainContext, completion: nil)
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
                print("No response etag or last modified for request with id: '\(requestId)', url: '\(response.httpResponse.URL?.absoluteString)'. Request needs to have a fingerprint (e.g. ETag or Last-Modified) for caching.")
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
            print("Data is \(isDataNew ? "" : "NOT ")new for this request.");
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
        
        let request = NSMutableURLRequest(URL: requestURL, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 5)
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
