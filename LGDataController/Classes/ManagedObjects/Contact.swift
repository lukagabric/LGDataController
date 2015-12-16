//
//  Contact.swift
//  LGDataController
//
//  Created by Luka Gabric on 15/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData
import ReactiveCocoa

@objc(Contact)
public class Contact: LGEntity {
    
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
    
    //MARK: Info
    
    var info: String {
        var nameComponents: [String] = [String]()
        if let lastName = self.lastName { nameComponents.append(lastName) }
        if let firstName = self.firstName { nameComponents.append(firstName) }
        var info = nameComponents.joinWithSeparator(", ")
        if let email = self.email { info.appendContentsOf(" (\(email))") }
        return info
    }
    
    //MARK: Producers
    
    lazy var firstNameProducer: SignalProducer<String, NoError> = {
        let firstNameProperty = DynamicProperty(object: self, keyPath: "firstName")
        let firstNameProducer = firstNameProperty.producer.map { $0 as? String ?? "" }
        return firstNameProducer
    }()
    
    lazy var lastNameProducer: SignalProducer<String, NoError> = {
        let lastNameProperty = DynamicProperty(object: self, keyPath: "lastName")
        let lastNameProducer = lastNameProperty.producer.map { $0 as? String ?? "" }
        return lastNameProducer
    }()
    
    lazy var companyProducer: SignalProducer<String, NoError> = {
        let companyProperty = DynamicProperty(object: self, keyPath: "company")
        let companyProducer = companyProperty.producer.map { $0 as? String ?? "" }
        return companyProducer
    }()
    
    lazy var emailProducer: SignalProducer<String, NoError> = {
        let emailProperty = DynamicProperty(object: self, keyPath: "email")
        let emailProducer = emailProperty.producer.map { $0 as? String ?? "" }
        return emailProducer
    }()
    
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
