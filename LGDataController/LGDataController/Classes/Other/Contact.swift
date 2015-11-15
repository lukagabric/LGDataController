//
//  Contact.swift
//  LGDataController
//
//  Created by Luka Gabric on 15/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData

@objc(Contact)
class Contact: NSManagedObject {

    override class var lg_entityName: String {
        return "Contact"
    }
    
    override var lg_dataUpdateMappings: [String : String] {
        return [String : String]()
    }

}
