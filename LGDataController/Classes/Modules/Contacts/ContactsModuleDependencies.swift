//
//  ContactsModuleDependencies.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

public protocol ContactsModuleDependencies {
    
    var contactsDataService: ContactsDataServiceType { get }
    var contactsNavigationService: ContactsNavigationServiceType { get }
    
}

public protocol ContactsDataServiceType {
    
    func contactsModelObserver() -> LGModelObserver<Contact>

    func updateProducerForContactWithId(contactId: String) -> SignalProducer<Contact?, NSError>?
//    func propertyUpdateProducerForContactWithId(contactId: String) -> SignalProducer<Contact?, NoError>
    func mutablePropertyForContactWithId(contactId: String) -> MutableProperty<Contact?>
//    func loadingProducerForContactWithId(contactId: String) -> SignalProducer<Bool, NoError>
    
}

public protocol ContactsNavigationServiceType {
    
    func pushContactDetails(contactId contactId: String)
    
}
