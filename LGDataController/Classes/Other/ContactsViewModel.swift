//
//  ContactsViewModel.swift
//  LGDataController
//
//  Created by Luka Gabric on 22/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa
import CoreData

public class ContactsViewModel {
    
    private let dataController: LGDataController
    
    public let contactsModelObserver: LGModelObserver<Contact>
    
    init(dataController: LGDataController) {
        self.dataController = dataController
        
        let contactsInteractor = ContactsInteractor(dataController: dataController)
        self.contactsModelObserver = contactsInteractor.contactsModelObserver()
        
        if self.contactsModelObserver.refreshSignal == nil {
            print("no refresh signal means data is not stale")
        }
        
        self.contactsModelObserver.refreshSignal?.observeCompleted {
            print("update completed")
        }
        
        self.contactsModelObserver.modelChangedSignalProducer.startWithNext { change in
            guard let sections = change.sections else { return }
            let firstSection = sections[0]
            guard let objects = firstSection.objects else { return }
            print(objects)
        }
        
        self.contactsModelObserver.fetchedObjectsSignalProducer.startWithNext { contacts in
            print(contacts)
        }
        
    }
    
}
