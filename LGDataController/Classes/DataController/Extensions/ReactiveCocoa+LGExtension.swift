//
//  ReactiveCocoa+LGExtension.swift
//  LGDataController
//
//  Created by Luka Gabric on 18/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

func lg_loadingProducerFrom<T, U>(producer: SignalProducer<T, U>?) -> SignalProducer<Bool, NoError> {
    guard let producer = producer else { return SignalProducer(value: false) }
    
    let (loadingProducer, loadingObserver) = SignalProducer<Bool, NoError>.buffer(1)
    loadingObserver.sendNext(true)
    
    producer
        .map { _ in false }
        .flatMapError { _ in SignalProducer<Bool, NoError>(value: false) }
        .takeLast(1)
        .start { event in
            if event.isTerminating {
                loadingObserver.sendNext(false)
                loadingObserver.sendCompleted()
            }
    }
    
    return loadingProducer
}

func lg_loadingHiddenProducerFrom<T, U>(producer: SignalProducer<T, U>?) -> SignalProducer<Bool, NoError> {
    return lg_loadingProducerFrom(producer).map { !$0 }
}

extension SignalProducerType {
    
    var lg_tableReloadProducer: SignalProducer<Void, NoError> {
        return self.map { _ in () }.flatMapError { _ in SignalProducer.empty }
    }
    
}
