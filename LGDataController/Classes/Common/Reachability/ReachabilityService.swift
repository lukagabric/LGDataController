//
//  ReachabilityService.swift
//  LGDataController
//
//  Created by Luka Gabric on 20/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

public class ReachabilityService {

    private let reach: Reachability

    public let reachabilityProducer: SignalProducer<Reachability, NoError>
    private let reachabilityObserver: Observer<Reachability, NoError>
    
    public let isOfflineProducer: SignalProducer<Bool, NoError>
    public let isOnlineProducer: SignalProducer<Bool, NoError>
    
    init() {
        self.reach = try! Reachability.reachabilityForInternetConnection()
        
        let (reachabilityProducer, reachabilityObserver) = SignalProducer<Reachability, NoError>.buffer(1)
        self.reachabilityProducer = reachabilityProducer.observeOn(UIScheduler())
        self.reachabilityObserver = reachabilityObserver
        
        self.isOnlineProducer = self.reachabilityProducer.map { reachability in reachability.isReachable() }
        self.isOfflineProducer = self.reachabilityProducer.map { reachability in !reachability.isReachable() }
        
        self.reach.whenReachable = { [weak self] reachability in
            self?.reachabilityObserver.sendNext(reachability)
        }
        self.reach.whenUnreachable = { [weak self] reachability in
            self?.reachabilityObserver.sendNext(reachability)
        }
        
        try! reach.startNotifier()
    }
    
}
