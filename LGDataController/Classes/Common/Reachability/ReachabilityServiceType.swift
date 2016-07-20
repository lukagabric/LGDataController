//
//  ReachabilityServiceType.swift
//  LGDataController
//
//  Created by Luka Gabric on 20/07/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

public protocol ReachabilityServiceType {
    
    var reachabilityProducer: SignalProducer<Reachability, NoError> { get }
    var isOnlineProducer: SignalProducer<Bool, NoError> { get }
    var isOfflineProducer: SignalProducer<Bool, NoError> { get }
    
}
