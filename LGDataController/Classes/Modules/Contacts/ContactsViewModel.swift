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

public class ContactsViewModel: ContactsViewModelType {
    
    public let loadingProducer: SignalProducer<Bool, NoError>
    public let contactsTitleProducer: SignalProducer<String, NoError>
    public let contacts = MutableProperty<[Contact]?>(nil)
    
    private let dataService: ContactsDataServiceType
    private let contactsModelObserver: LGModelObserver<Contact>

    init(dependencies: ContactsModuleDependencies) {
        self.dataService = dependencies.contactsDataService
        self.contactsModelObserver = self.dataService.contactsModelObserver()
        
        self.loadingProducer = self.contactsModelObserver.loadingProducer
        self.contacts <~ self.contactsModelObserver.fetchedObjectsProducer
        self.contactsTitleProducer = self.contactsModelObserver.fetchedObjectsProducer.map { contacts -> String in
            guard let allContacts = contacts else { return "0 contact(s)" }
            return "\(String(allContacts.count)) contact(s)"
        }
    }
    
}
