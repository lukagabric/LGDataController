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
    
    //MARK: - Entity Name
    
    override class func lg_entityName() -> String {
        return "Contact"
    }
    
    //MARK: - Mappings
    
    static var mappings: [String : String] = [
        "id" : "guid",
    ]
    
    override class func lg_responseToEntityMappings() -> [String : String] {
        return mappings
    }
    
    //MARK: Parsing Data
    
    class func parseFullContactsData(data: NSArray, context: NSManagedObjectContext) -> [Contact] {
        let guids = data.valueForKey("id") as! [String]
        let contacts: [Contact] = context.lg_existingObjectsOrStubs(guids: guids, guidKey: "guid")
        let contactsByGuid: [String : Contact] = contacts.lg_indexedByKeyPath("guid")
        for contactDict in data as! [[String : AnyObject]] {
            let guid = contactDict["id"] as! String
            guard let contact = contactsByGuid[guid] else { continue }
            contact.lg_mergeWithDictionary(contactDict)
            contact.weight = NSNumber(integer: LGContentWeight.Full.rawValue)
        }
        return contacts
    }
    
    //MARK: Debug
    
    func debugLog() {
        print("Guid: \(self.guid)")
        print("First name: \(self.firstName)")
        print("Last name: \(self.lastName)")
        print("Company: \(self.company)")
        print("Last name: \(self.lastName)")
        print("Email: \(email)")
    }
    
    //MARK: -

}
