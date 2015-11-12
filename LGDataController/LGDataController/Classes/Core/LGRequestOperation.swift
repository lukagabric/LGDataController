//
//  LGRequestOperation.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

class LGRequestOperation: LGConcurrentOperation {
    
    let session: NSURLSession
    let request: NSURLRequest
    let signalProducer: SignalProducer<(NSData, NSURLResponse), NSError>
    var signalDisposable: Disposable?
    
    init(session: NSURLSession, request: NSURLRequest) {
        self.session = session
        self.request = request
        
        self.signalProducer = self.session.rac_dataWithRequest(request)

        super.init()
    }
    
    override func main() {
        self.signalDisposable = self.signalProducer.start()
    }
    
    override func cancel() {
        self.signalDisposable?.dispose()
        super.cancel()
    }
    
}
