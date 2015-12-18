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

public class Contact: ContentEntity {
    
    //MARK: - Entity Name
    
    override class func lg_entityName() -> String {
        return "Contact"
    }
    
    //MARK: - Mappings
    
    static var mappings: [String : String] = [
        "objectId" : "guid"
    ]
    
    override class func lg_responseToEntityMappings() -> [String : String] {
        return mappings
    }
    
    //MARK: Parsing Payload
    
    class func parseAllContactsPayload(payload: NSArray, weight: LGContentWeight, payloadGuidKey: String, context: NSManagedObjectContext) -> [Contact] {
        let allContacts: [Contact] = context.lg_allObjects()
        var contactsByGuid: [String : Contact] = allContacts.lg_indexedByKeyPath("guid")
        
        var resultContacts = [Contact]()
        for payloadDict in payload as! [[String : AnyObject]] {
            let guid = payloadDict[payloadGuidKey] as! String
            let contact: Contact
            if let c = contactsByGuid.removeValueForKey(guid) {
                contact = c
            }
            else {
                contact = NSEntityDescription.insertNewObjectForEntityForName(Contact.lg_entityName(), inManagedObjectContext: context) as! Contact
            }
            
            if contact.contentWeight != weight || contact.updatedAtString != payloadDict["updatedAt"] as? String {
                self.parsePayloadForContact(contact, payloadDict: payloadDict, context: context)
                
                contact.updateForPayloadWeight(weight)
            }

            contact.markAsPermanentInContext(context)

            resultContacts.append(contact)
        }
        
        for (_, contact) in contactsByGuid {
            context.deleteObject(contact)
        }
        
        return resultContacts
    }
    
    class func parseContactsPayload(payload: NSArray, weight: LGContentWeight, isPermanent: Bool = true, payloadGuidKey: String, context: NSManagedObjectContext) -> [Contact] {
        let guids = payload.valueForKey(payloadGuidKey) as! [String]
        let contacts: [Contact] = context.lg_existingObjectsOrStubs(guids: guids, guidKey: "guid")
        let contactsByGuid: [String : Contact] = contacts.lg_indexedByKeyPath("guid")
        for payloadDict in payload as! [[String : AnyObject]] {
            let guid = payloadDict[payloadGuidKey] as! String
            guard let contact = contactsByGuid[guid] else { continue }
            
            self.parsePayloadForContact(contact, payloadDict: payloadDict, context: context)
            contact.updateForPayloadWeight(weight)
            if isPermanent {
                contact.markAsPermanentInContext(context)
            }
            else {
                contact.markAsSessionInContext(context)
            }
        }
        
        return contacts
    }
    
    class func parsePayloadForContact(contact: Contact, payloadDict: [String : AnyObject], context: NSManagedObjectContext) {
        contact.lg_mergeWithDictionary(payloadDict)
        //No other actions needed but this would be used to handle relationship
    }
    
    override public func lg_mergeWithDictionary(dictionary: [String : AnyObject]) {
        super.lg_mergeWithDictionary(dictionary)
        self.updatedAtString = dictionary["updatedAt"] as? String
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
