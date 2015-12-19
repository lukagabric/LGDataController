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
    
    public let contacts = MutableProperty<[Contact]?>(nil)
    public let loadingHidden = MutableProperty<Bool>(true)
    public let contactsTitleProducer: SignalProducer<String, NoError>
    
    private let dataService: ContactsDataServiceType
    private let contactsModelObserver: LGModelObserver<Contact>
    private let navigationService: ContactsNavigationServiceType
    
    //MARK: - Init

    init(dependencies: ContactsModuleDependencies) {
        self.dataService = dependencies.contactsDataService
        self.navigationService = dependencies.contactsNavigationService
        self.contactsModelObserver = self.dataService.contactsModelObserver()
        
        self.contacts <~ self.contactsModelObserver.fetchedObjectsProducer
        self.contactsTitleProducer = self.contactsModelObserver.fetchedObjectsProducer.map { contacts -> String in
            guard let contacts = contacts else { return "0 contact(s)" }
            return "\(String(contacts.count)) contact(s)"
        }
        
        if self.contacts.value == nil || self.contacts.value!.count == 0 {
            self.loadingHidden <~ loadingHiddenProducerFrom(self.contactsModelObserver.refreshProducer)
        }
    }
    
    //MARK: - User Interaction
    
    public func didSelectContact(contact: Contact) {
        self.navigationService.pushContactDetails(contactId: contact.guid!)
    }
    
    //MARK: -

}
