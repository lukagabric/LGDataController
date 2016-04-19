//
//  ReactiveCocoa+LGExtension.swift
//  LGDataController
//
//  Created by Luka Gabric on 18/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa
import CoreData

func lg_loadingProducerFrom<T, U>(producer: SignalProducer<T, U>?) -> SignalProducer<Bool, NoError> {
    guard let producer = producer else { return SignalProducer(value: false) }
    
    return producer.lg_loadingProducer
}

func lg_loadingHiddenProducerFrom<T, U>(producer: SignalProducer<T, U>?) -> SignalProducer<Bool, NoError> {
    return lg_loadingProducerFrom(producer).map { !$0 }
}

extension SignalProducerType {
    
    var lg_loadingProducer: SignalProducer<Bool, NoError> {
        let trueProducer = SignalProducer<Bool, NoError>(value: true)
        
        let falseOnLoadCompleteProducer = self
            .map { _ in false }
            .flatMapError { _ in SignalProducer<Bool, NoError>(value: false) }
        
        return trueProducer.concat(falseOnLoadCompleteProducer)
    }
    
    var lg_loadingViewHiddenProducer: SignalProducer<Bool, NoError> {
        return self.lg_loadingProducer.map { !$0 }
    }
    
    var lg_tableReloadProducer: SignalProducer<Void, NoError> {
        return self.map { _ in () }.flatMapError { _ in SignalProducer.empty }
    }
    
}

func lg_producerForObject<T: NSManagedObject>(object: T?, updateProducer: SignalProducer<T?, NSError>?) -> SignalProducer<T?, NSError> {
    if object != nil {
        return SignalProducer(value: object)
    }
    else if updateProducer != nil {
        return updateProducer!
    }
    else {
        return SignalProducer(value: nil)
    }
}
