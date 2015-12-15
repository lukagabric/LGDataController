//
//  ContactsDataService.swift
//  LGDataController
//
//  Created by Luka Gabric on 22/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa
import CoreData

public class ContactsDataService: ContactsDataServiceType {
    
    private let dataController: DataController
    
    //MARK: - Init
    
    init(dataController: DataController) {
        self.dataController = dataController
    }
    
    //MARK: - Contacts Model Observer
    
    public func contactsModelObserver() -> LGModelObserver<Contact> {
        let contactsFrc = self.contactsFrc()
        let updateProducer = self.contactsUpdateProducer()
        
        return LGModelObserver(fetchedResultsController: contactsFrc, updateProducer: updateProducer)
    }
    
    private func contactsFrc() -> NSFetchedResultsController {
        let contactsFetchRequest = NSFetchRequest(entityName: Contact.lg_entityName())
        let sortDescriptor = NSSortDescriptor(key: "lastName", ascending: true)
        contactsFetchRequest.sortDescriptors = [sortDescriptor]
        
        let contactsFrc = NSFetchedResultsController(
            fetchRequest: contactsFetchRequest,
            managedObjectContext: self.dataController.mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return contactsFrc;
    }
    
    private func contactsUpdateProducer() -> SignalProducer<[Contact]?, NSError>? {
        let contactsUpdateProducer = self.dataController.updateData(
            url: "http://lukagabric.com/wp-content/contacts-api/contacts",
            methodName: "GET",
            parameters: nil,
            requestId: "ContactsJSON",
            staleInterval: 10) { (data, response, context) -> [Contact]? in
                let contacts = Contact.parseFullContactsData(data as! NSArray, context: context)
                return contacts
        }

        return contactsUpdateProducer
    }
    
    public func contactWithId(contactId: String) -> Contact? {
        let fetchRequest = NSFetchRequest(entityName: Contact.lg_entityName())
        let predicate = NSPredicate(format: "guid == %@", contactId)
        fetchRequest.predicate = predicate
        
        let contact = try! self.dataController.mainContext.executeFetchRequest(fetchRequest).first as? Contact
        
        return contact
    }

    public func producerAndContactWithId(contactId: String) -> (Contact?, SignalProducer<Contact?, NSError>?) {
        let contact = self.contactWithId(contactId)

        let contactUpdateProducer: SignalProducer<Contact?, NSError>? = self.dataController.updateData(
            url: "http://lukagabric.com/wp-content/contacts-api/contacts",
            methodName: "GET",
            parameters: nil,
            requestId: "ContactDetailsJSON",
            staleInterval: 10) { (data, response, context) -> Contact? in
                let contacts = Contact.parseFullContactsData(data as! NSArray, context: context)
                for contact in contacts {
                    if let guid = contact.guid where guid == contactId {
                        return contact
                    }
                }
                
                return nil
        }
        
        return (contact, contactUpdateProducer)
    }
    

    //MARK: -
    
}
