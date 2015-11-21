//
//  LGContextTransferable.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData

protocol LGContextTransferable {
    typealias TransferredType
    
    func transferredToContext(context: NSManagedObjectContext) -> TransferredType
}
