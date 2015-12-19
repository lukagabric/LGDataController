//
//  ReactiveCocoa+LGExtension.swift
//  LGDataController
//
//  Created by Luka Gabric on 18/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

func loadingProducerFrom<T, U>(producer: SignalProducer<T, U>?) -> SignalProducer<Bool, NoError> {
    guard let producer = producer else { return SignalProducer<Bool, NoError>(value: false) }
    
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

func mutablePropertyForObject<T>(object: T?, updateProducer: SignalProducer<T?, NSError>?) -> MutableProperty<T?> {
    let objectMutableProperty = MutableProperty<T?>(object)
    
    if object != nil {
        return objectMutableProperty
    }
    
    let objectUpdateProducer = updateProducer ?? SignalProducer<T?, NSError>.empty
    let updateNoErrorProducer = objectUpdateProducer.flatMapError { _ in SignalProducer<T?, NoError>.empty }
    
    objectMutableProperty <~ updateNoErrorProducer
    
    return objectMutableProperty
}

func loadingHiddenProducerFrom<T, U>(producer: SignalProducer<T, U>?) -> SignalProducer<Bool, NoError> {
    return loadingProducerFrom(producer).map { !$0 }
}

extension UITableView {
    public func reloadWithProducer<T>(producer: SignalProducer<T, NoError>) {
        producer.startWithNext { [weak self] _ in self?.reloadData() }
    }
}
