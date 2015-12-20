//
//  LGReachability.swift
//  LGDataController
//
//  Created by Luka Gabric on 20/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

public protocol ReachabilityType {

    var reachabilityProducer: SignalProducer<Reachability, NoError> { get }
    
}

public class LGReachability: ReachabilityType {

    private let reachability: Reachability
    public let reachabilityProducer: SignalProducer<Reachability, NoError>
    private let reachabilityObserver: Observer<Reachability, NoError>
    
    init() {
        self.reachability = try! Reachability.reachabilityForInternetConnection()
        try! reachability.startNotifier()
        
        (self.reachabilityProducer, self.reachabilityObserver) = SignalProducer.buffer(1)
        
        self.reachability.whenReachable = { [weak self] reachability in
            self?.reachabilityObserver.sendNext(reachability)
        }
        self.reachability.whenUnreachable = { [weak self] reachability in
            self?.reachabilityObserver.sendNext(reachability)
        }
    }
    
}
