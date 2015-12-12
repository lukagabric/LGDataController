//
//  ContactsInteractor.swift
//  LGDataController
//
//  Created by Luka Gabric on 22/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa
import CoreData

public class ContactsInteractor {
    
    private let dataController: DataController
    
    init(dependencies: ContactsModuleDependencies) {
        self.dataController = dependencies.dataController
    }
    
    public func contactsModelObserver() -> LGModelObserver<Contact> {
        let contactsFrc = self.contactsFrc()
        let updateSignal = self.contactsUpdateSignal()
        
        return LGModelObserver(fetchedResultsController: contactsFrc, updateSignal: updateSignal)
    }
    
    public func contactsFrc() -> NSFetchedResultsController {
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
    
    private func contactsUpdateSignal() -> Signal<[Contact], NSError>? {
        let contactsUpdateSignal = self.dataController.updateData(
            url: "http://lukagabric.com/wp-content/contacts-api/contacts",
            methodName: "GET",
            parameters: nil,
            requestId: "ContactsJSON",
            staleInterval: 10) { (data, response, context) -> [Contact] in
                let contacts = Contact.parseFullContactsData(data as! NSArray, context: context)
                return contacts
        }

        return contactsUpdateSignal
    }
    
}
