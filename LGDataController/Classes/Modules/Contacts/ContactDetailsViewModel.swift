//
//  ContactDetailsViewModel.swift
//  LGDataController
//
//  Created by Luka Gabric on 15/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

public class ContactDetailsViewModel: ContactDetailsViewModelType {
    
    public let contact: MutableProperty<Contact?>
    public let updateProducer: SignalProducer<Contact?, NSError>?

    private let contactId: String
    private let dataService: ContactsDataServiceType
    
    init(dependencies: ContactsModuleDependencies, contactId: String) {
        self.dataService = dependencies.contactsDataService
        self.contactId = contactId

        self.contact = self.dataService.mutablePropertyForContactWithId(contactId)
        self.updateProducer = self.dataService.updateProducerForContactWithId(contactId)
    }
    
}