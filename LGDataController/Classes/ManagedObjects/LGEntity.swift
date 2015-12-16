//
//  LGEntity.swift
//  LGDataController
//
//  Created by Luka Gabric on 16/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData

public class LGEntity: NSManagedObject {

    var contentWeight: LGContentWeight {
        guard let weight = self.weight else { return .Stub }
        
        if weight == LGContentWeight.Full.rawValue { return .Light }
        if weight == LGContentWeight.Full.rawValue { return .Full }
        
        return .Stub
    }
    
}
