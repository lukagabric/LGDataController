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

    public let signal: Signal<(NSData, NSURLResponse), NSError>

    let session: NSURLSession
    let request: NSURLRequest
    let signalProducer: SignalProducer<(NSData, NSURLResponse), NSError>
    var signalDisposable: Disposable?
    let observer: Observer<(NSData, NSURLResponse), NSError>

    init(session: NSURLSession, request: NSURLRequest) {
        self.session = session
        self.request = request
        
        self.signalProducer = self.session.rac_dataWithRequest(request).retry(1)

        let (signal, observer) = Signal<(NSData, NSURLResponse), NSError>.pipe()
        self.signal = signal.takeLast(1)
        self.observer = observer

        super.init()
    }
    
    override public func main() {
        self.signalDisposable = self.signalProducer.start(self.observer)
    }
    
    override public func cancel() {
        self.signalDisposable?.dispose()
        
        super.cancel()
    }
    
}
