//
//  LGReachabilityService.swift
//  LGDataController
//
//  Created by Luka Gabric on 20/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

public protocol ReachabilityServiceType {

    var reachability: MutableProperty<Reachability> { get }
    var isOffline: MutableProperty<Bool> { get }
    var isOnline: MutableProperty<Bool> { get }

}

public class LGReachabilityService: ReachabilityServiceType {

    private let reach: Reachability
    private let reachabilityProducer: SignalProducer<Reachability, NoError>
    private let reachabilityObserver: Observer<Reachability, NoError>
    
    lazy public var reachability: MutableProperty<Reachability> = {
        let reachability = MutableProperty(self.reach)
        reachability <~ self.reachabilityProducer
        return reachability
    }()
    
    lazy public var isOffline: MutableProperty<Bool> = {
        let isOffline = MutableProperty(true)
        isOffline <~ self.reachabilityProducer.map { reachability in !reachability.isReachable() }
        return isOffline
    }()
    
    lazy public var isOnline: MutableProperty<Bool> = {
        let isOnline = MutableProperty(true)
        isOnline <~ self.reachabilityProducer.map { reachability in reachability.isReachable() }
        return isOnline
    }()
    
    init() {
        self.reach = try! Reachability.reachabilityForInternetConnection()
        try! reach.startNotifier()
        
        let (reachabilityProducer, reachabilityObserver) = SignalProducer<Reachability, NoError>.buffer(1)
        self.reachabilityProducer = reachabilityProducer.observeOn(UIScheduler())
        self.reachabilityObserver = reachabilityObserver
        
        self.reach.whenReachable = { [weak self] reachability in
            self?.reachabilityObserver.sendNext(reachability)
        }
        self.reach.whenUnreachable = { [weak self] reachability in
            self?.reachabilityObserver.sendNext(reachability)
        }
    }
    
}
