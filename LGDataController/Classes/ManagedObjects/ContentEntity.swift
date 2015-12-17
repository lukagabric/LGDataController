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

public class ContentEntity: NSManagedObject {

    var contentWeight: LGContentWeight {
        guard let weight = self.weight else { return .Stub }
        
        if weight == LGContentWeight.Light.rawValue { return .Light }
        if weight == LGContentWeight.Full.rawValue { return .Full }
        
        return .Stub
    }
    
    lazy var weightProducer: SignalProducer<String, NoError> = {
        let weightProperty = DynamicProperty(object: self, keyPath: "weight")
        let weightProducer = weightProperty.producer.map { value -> String in
            guard let weight = value as? NSNumber else { return "Not set" }
            
            if weight == LGContentWeight.Light.rawValue { return "Light" }
            if weight == LGContentWeight.Full.rawValue { return "Full" }
            
            return "Stub"
        }
        return weightProducer
    }()

    func updateForPayloadWeight(weight: LGContentWeight) {
        if weight == .Full {
            self.weight = NSNumber(integer: LGContentWeight.Full.rawValue)
        }
        else if self.contentWeight != .Full {
            self.weight = NSNumber(integer: LGContentWeight.Light.rawValue)
        }
    }
    
}
