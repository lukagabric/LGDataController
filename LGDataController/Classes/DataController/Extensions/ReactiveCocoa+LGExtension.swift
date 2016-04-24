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

extension SignalProducerType {
    
    var lg_tableReloadProducer: SignalProducer<Void, NoError> {
        return self.map { _ in () }.flatMapError { _ in SignalProducer.empty }
    }
    
    var lg_voidValue: SignalProducer<Void, Self.Error> {
        return self.map { _ in () }
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

func lg_loadingViewProducer<T>(objectProducer objectProducer: SignalProducer<T?, NoError>, updateProducer: SignalProducer<Void, NSError>) -> SignalProducer<Void, NSError> {
    let objectProducer = objectProducer
        .filter { $0 != nil }
        .map { _ in () }
        .promoteErrors(NSError.self)
    let mergedProducer = SignalProducer<SignalProducer<Void, NSError>, NSError>(values: [objectProducer, updateProducer]).flatten(.Merge).take(1)
    return mergedProducer
}
