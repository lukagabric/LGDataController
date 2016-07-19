//
//  ContentEntity.swift
//  LGDataController
//
//  Created by Luka Gabric on 16/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData
import ReactiveCocoa

public class ContentEntity: NSManagedObject, ContentEntityType {
    
    //MARK: - Entity Name
    
    override class func lg_entityName() -> String {
        return "ContentEntity"
    }

    //MARK: - ContentEntityType
    
    func shouldUpdateData(weight weight: ContentWeight, payloadDict: [String : AnyObject]) -> Bool {
        return self.contentWeight.rawValue < weight.rawValue || self.updatedAtString != payloadDict["updatedAt"] as? String
    }
    
    func updateForPayloadWeight(weight: ContentWeight) {
        if weight.rawValue > self.contentWeight.rawValue {
            self.contentWeight = weight
        }
    }
    
    func markAsPermanent(permanent: Bool) {
        let isCurrentlyPermanent = self.permanent?.boolValue ?? false
        self.permanent = isCurrentlyPermanent || permanent
    }
    
    public var contentWeight: ContentWeight {
        get {
            guard let weight = self.weight else { return .Stub }
            
            if weight == ContentWeight.Light.rawValue { return .Light }
            if weight == ContentWeight.Full.rawValue { return .Full }
            
            return .Stub
        }
        set(contentWeight) {
            self.weight = NSNumber(integer: contentWeight.rawValue)
        }
    }
    
    //MARK: - Producers
    
    lazy public var weightProducer: SignalProducer<String, NoError> = {
        let weightProperty = DynamicProperty(object: self, keyPath: "weight")
        let weightProducer = weightProperty.producer.map { value -> String in
            guard let weight = value as? NSNumber else { return "Not set" }
            
            if weight == ContentWeight.Light.rawValue { return "Light" }
            if weight == ContentWeight.Full.rawValue { return "Full" }
            
            return "Stub"
        }
        return weightProducer.takeUntil(self.deleteProducer)
    }()
    
    lazy var deleteProducer: SignalProducer<Void, NoError> = {
        let (deleteProducer, deleteObserver) = SignalProducer<Void, NoError>.buffer(1)
        self.deleteObserver = deleteObserver
        return deleteProducer.takeLast(1)
    }()
    
    private var deleteObserver: Observer<Void, NoError>?
    
    //MARK: - Override
    
    override public func prepareForDeletion() {
        if let observer = self.deleteObserver {
            observer.sendNext()
            observer.sendCompleted()
        }
    }
    
    //MARK: -
    
}
