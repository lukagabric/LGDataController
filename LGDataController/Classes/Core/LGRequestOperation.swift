//
//  LGRequestOperation.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

public class LGRequestOperation: LGConcurrentOperation {

    public let signal: Signal<LGResponse, NSError>
    private let observer: Observer<LGResponse, NSError>
    private var disposable: Disposable?
    
    private var signalProducer: SignalProducer<LGResponse, NSError>!

    private let session: NSURLSession
    private let request: NSURLRequest
    
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
    
    override public func main() {
        self.disposable = self.signalProducer.start(self.observer)
    }
    
    override public func cancel() {
        self.disposable?.dispose()
        
        super.cancel()
    }
    
}
