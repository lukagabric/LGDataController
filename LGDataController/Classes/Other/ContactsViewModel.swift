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
    
    private let contactsInteractor: ContactsInteractor
    private let contactsModelObserver: LGModelObserver<Contact>
    
    public let contactsCount = MutableProperty<String>("No contacts")
    public let isLoadingContacts = MutableProperty<Bool>(false)
    public let contacts = MutableProperty<[Contact]?>(nil)
        
    init(dataController: LGDataController) {
        self.dataController = dataController
        self.contactsInteractor = ContactsInteractor(dataController: dataController)
        self.contactsModelObserver = contactsInteractor.contactsModelObserver()
        
        self.contacts <~ self.contactsModelObserver.fetchedObjectsSignalProducer

        self.contactsCount <~ self.contactsModelObserver.fetchedObjectsSignalProducer.map { contacts -> String in
            guard let allContacts = contacts else { return "No contacts" }
            return "\(String(allContacts.count)) contact(s)"
        }

        if let refreshSignal = self.contactsModelObserver.refreshSignalNoError {
            isLoadingContacts.value = true
            isLoadingContacts <~ refreshSignal.map { _ in false }
        }
        
    }
    
}
