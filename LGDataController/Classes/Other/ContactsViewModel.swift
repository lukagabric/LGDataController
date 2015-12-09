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
    
    public let loadingProducer: SignalProducer<Bool, NoError>
    public let contactsCountProducer: SignalProducer<String, NoError>
    public let contacts = MutableProperty<[Contact]?>(nil)
    
    private let dataController: LGDataController
    private let contactsInteractor: ContactsInteractor
    private let contactsModelObserver: LGModelObserver<Contact>

    init(dataController: LGDataController) {
        self.dataController = dataController
        self.contactsInteractor = ContactsInteractor(dataController: dataController)
        self.contactsModelObserver = contactsInteractor.contactsModelObserver()
        
        self.contactsCountProducer = self.contactsModelObserver.fetchedObjectsSignalProducer.map { contacts -> String in
            guard let allContacts = contacts else { return "0 contact(s)" }
            return "\(String(allContacts.count)) contact(s)"
        }
        
        self.contacts <~ self.contactsModelObserver.fetchedObjectsSignalProducer

        self.loadingProducer = self.contactsModelObserver.loadingSignalProducer
    }
    
}
