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

public class ContentEntity: NSManagedObject, LGContentEntityType {

    public var contentWeight: LGContentWeight {
        
        get {
            guard let weight = self.weight else { return .Stub }
            
            if weight == LGContentWeight.Light.rawValue { return .Light }
            if weight == LGContentWeight.Full.rawValue { return .Full }
            
            return .Stub
        }
        
        set(contentWeight) {
            self.weight = NSNumber(integer: contentWeight.rawValue)
        }
        
    }
    
    lazy public var weightProducer: SignalProducer<String, NoError> = {
        let weightProperty = DynamicProperty(object: self, keyPath: "weight")
        let weightProducer = weightProperty.producer.map { value -> String in
            guard let weight = value as? NSNumber else { return "Not set" }
            
            if weight == LGContentWeight.Light.rawValue { return "Light" }
            if weight == LGContentWeight.Full.rawValue { return "Full" }
            
            return "Stub"
        }
        return weightProducer
    }()
    
    lazy var deleteProducer: SignalProducer<Void, NoError> = {
        let (deleteProducer, deleteObserver) = SignalProducer<Void, NoError>.buffer(1)
        self.deleteObserver = deleteObserver
        return deleteProducer
    }()
    
    private var deleteObserver: Observer<Void, NoError>?
    
    override public func prepareForDeletion() {
        if let observer = self.deleteObserver {
            observer.sendNext()
            observer.sendCompleted()
        }
    }

    func updateForPayloadWeight(weight: LGContentWeight) {
        if weight == .Full {
            self.contentWeight = .Full
        }
        else if self.contentWeight != .Full {
            self.contentWeight = .Light
        }
    }
    
    func markAsPermanentInContext(context: NSManagedObjectContext) {
        self.permanentEntity = PermanentEntity.permanentEntityInContext(context)
    }

    func markAsSessionInContext(context: NSManagedObjectContext) {
        self.sessionEntity = SessionEntity.sessionEntityInContext(context)
    }

}
