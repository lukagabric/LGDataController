//
//  LGRequestOperation.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

public struct LGResponse {
    
    let httpResponse: NSHTTPURLResponse
    let responseData: NSData
    let eTag: String?
    let lastModified: String?
    let statusCode: Int
    
    init(response: NSHTTPURLResponse, data: NSData) {
        self.httpResponse = response
        self.responseData = data
        self.statusCode = response.statusCode
        self.eTag = self.httpResponse.allHeaderFields["Etag"] as? String
        self.lastModified = self.httpResponse.allHeaderFields["Last-Modified"] as? String
    }
    
}

public class LGRequestOperation: NSOperation {

    public let signal: Signal<LGResponse, NSError>
    private let observer: Observer<LGResponse, NSError>
    private var disposable: Disposable?
    
    private var signalProducer: SignalProducer<LGResponse, NSError>!

    private let session: NSURLSession
    private let request: NSURLRequest
    
    //MARK: - Init
    
    init(session: NSURLSession, request: NSURLRequest) {
        self.session = session
        self.request = request
        
        let (signal, observer) = Signal<LGResponse, NSError>.pipe()
        self.signal = signal.takeLast(1)
        
        self.observer = observer

        super.init()
        
        self.signalProducer = self.session.rac_dataWithRequest(request)
            .retry(1)
            .map { (data, response) -> LGResponse in
                let response = LGResponse(response: response as! NSHTTPURLResponse, data: data)
                return response
            }
            .observeOn(QueueScheduler.init(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)))
            .on(failed: { [weak self] _ in self?.completeOperation() },
                completed: { [weak self] in self?.completeOperation() })
    }
    
    //MARK: - Override
    
    override public func main() {
        self.disposable = self.signalProducer.start(self.observer)
    }
    
    override public func cancel() {
        self.disposable?.dispose()
        
        super.cancel()
    }
    
    //MARK: - Concurrency
    
    public override var asynchronous: Bool {
        return true
    }
    
    private var _executing: Bool = false
    public override var executing: Bool {
        get {
            return _executing
        }
        set {
            if (_executing != newValue) {
                self.willChangeValueForKey("isExecuting")
                _executing = newValue
                self.didChangeValueForKey("isExecuting")
            }
        }
    }
    
    private var _finished: Bool = false;
    public override var finished: Bool {
        get {
            return _finished
        }
        set {
            if (_finished != newValue) {
                self.willChangeValueForKey("isFinished")
                _finished = newValue
                self.didChangeValueForKey("isFinished")
            }
        }
    }
    
    public override func start() {
        if (cancelled) {
            finished = true
            return
        }
        
        executing = true
        
        main()
    }
    
    func completeOperation() {
        executing = false
        finished  = true
    }
    
    //MARK: -
    
}
