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
    
    private let dataController: LGDataController
    
    init(dataController: LGDataController) {
        self.dataController = dataController
    }
    
    func contactsModelObserver() -> LGModelObserver {
        let contactsUpdateSignal = self.dataController.updateData(
            url: "http://lukagabric.com/wp-content/contacts-api/contacts",
            methodName: "GET",
            parameters: nil,
            requestId: "ContactsJSON",
            staleInterval: 10) { (data, response, context) -> [Contact] in
                let contacts = Contact.parseFullContactsData(data as! NSArray, context: context)
                return contacts
        }
        
        let contactsFetchRequest = NSFetchRequest(entityName: Contact.lg_entityName())
        let sortDescriptor = NSSortDescriptor(key: "lastName", ascending: true)
        contactsFetchRequest.sortDescriptors = [sortDescriptor]
        
        let frc = NSFetchedResultsController(
            fetchRequest: contactsFetchRequest,
            managedObjectContext: self.dataController.mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        let modelObserver: LGModelObserver = LGModelObserver(fetchedResultsController: frc, refreshSignal: self.dataController.refreshSignal(inputSignal: contactsUpdateSignal))
        return modelObserver
    }
    
}
