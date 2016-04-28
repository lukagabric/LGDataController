//
//  DataController.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa
import CoreData

public enum RequestMethod: String {
    case Get = "GET"
    case Post = "POST"
    case Put = "PUT"
    case Delete = "DELETE"
}

public protocol ContextTransferableType {
    associatedtype TransferredType
    func transferredToContext(context: NSManagedObjectContext) -> TransferredType
}

public class UpdateInfo {
    
    var requestId: String
    var eTag: String?
    var lastModified: String?
    var updateDate: NSDate
    
    init(requestId: String) {
        self.requestId = requestId
        self.updateDate = NSDate.distantPast()
    }
    
}

public class DataController {
    
    let session: NSURLSession
    public let mainContext: NSManagedObjectContext
    let bgContext: NSManagedObjectContext
    let dataDownloadQueue: NSOperationQueue
    var activeUpdates: [String : Any]
    var updateInfoCache: [String : UpdateInfo]
    
    //MARK: - Init
    
    init(session: NSURLSession, mainContext: NSManagedObjectContext) {
        self.session = session
        self.mainContext = mainContext
        
        self.bgContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.bgContext.parentContext = self.mainContext
        
        self.dataDownloadQueue = NSOperationQueue()
        self.dataDownloadQueue.maxConcurrentOperationCount = 1
        
        self.updateInfoCache = [String : UpdateInfo]()
        
        self.activeUpdates = [String : Any]()
    }
    
    //MARK: - Main
    
    public func updateData<T where T: ContextTransferableType>(
        url url: String,
            method: RequestMethod = .Get,
            parameters: [String : AnyObject]? = nil,
            requestId: String? = nil,
            staleInterval: NSTimeInterval = 60,
            dataUpdate: (payload: Any, response: ServerResponse, context: NSManagedObjectContext) -> T?) -> SignalProducer<T?, NSError>? {
        assert(NSThread.currentThread().isMainThread, "Must be called on main thread")
        
        let requestId = requestId ?? url
        
        if let activeUpdateProducer = self.activeUpdates[requestId] {
            return activeUpdateProducer as? SignalProducer<T?, NSError>
        }
        
        if !self.isDataStale(reqestId: requestId, staleInterval: staleInterval) { return nil }
        
        guard let request = self.createRequest(requestId: requestId, url: url, method: method, parameters: parameters) else { return  nil }
        
        let operation = ServerRequestOperation(session: self.session, request: request)
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
            
            guard let serializedPayload = self.serializedPayload(response: response) else {
                dispatch_async(dispatch_get_main_queue(), {
                    updateObserver.sendFailed(NSError(domain: "Unable to serialize data", code: 0, userInfo: nil))
                })
                return
            }
            
            self.bgContext.performBlock {
                let resultData = dataUpdate(payload: serializedPayload, response: response, context: self.bgContext)
                
                self.bgContext.lg_saveToPersistentStore {
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
        self.mainContext.lg_saveToPersistentStore(nil)
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
    
    func isDataNew(reqestId requestId: String, response: ServerResponse) -> Bool {
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
    
    func refreshUpdateInfo(reqestId requestId: String, response: ServerResponse) -> UpdateInfo {
        let updateInfo = self.updateInfoForRequestId(requestId)
        updateInfo.eTag = response.eTag
        updateInfo.lastModified = response.lastModified
        updateInfo.updateDate = NSDate()
        return updateInfo
    }
    
    func updateInfoForRequestId(requestId: String) -> UpdateInfo {
        if let updateInfo = self.updateInfoCache[requestId] {
            return updateInfo
        }
        
        let newUpdateInfo = UpdateInfo(requestId: requestId)
        self.updateInfoCache[requestId] = newUpdateInfo
        return newUpdateInfo
    }
    
    //MARK: - Response
    
    func validateResponse(response: ServerResponse) -> NSError? {
        return nil
    }
    
    func serializedPayload(response response: ServerResponse) -> AnyObject? {
        return try? NSJSONSerialization.JSONObjectWithData(response.payload, options: [])
    }
    
    //MARK: - Request Convenience
    
    func createRequest(requestId requestId: String, url: String, method: RequestMethod, parameters: [String : AnyObject]?) -> NSURLRequest? {
        var completeUrl = url
        
        if parameters != nil && method == .Get {
            let paramsString = self.queryStringFromParameters(parameters!)
            if paramsString != nil {
                completeUrl.appendContentsOf("?\(paramsString!)")
            }
        }
        
        guard let requestURL = NSURL(string: completeUrl) else { return nil }
        
        let request = NSMutableURLRequest(URL: requestURL, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 5)
        request.HTTPMethod = method.rawValue
        
        if parameters != nil && method == .Post {
            let parametersData = try? NSJSONSerialization.dataWithJSONObject(parameters!, options: [])
            request.HTTPBody = parametersData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if method == .Get {
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
