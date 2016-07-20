//
//  ContactsDataServiceType.swift
//  LGDataController
//
//  Created by Luka Gabric on 20/07/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

public protocol ContactsDataServiceType {
    
    func contactsModelObserver() -> ModelObserver<Contact>
    func contactModelObserver(contactId contactId: String, weight: ContentWeight) -> ModelObserver<Contact>
    func contactsUpdateProducer() -> SignalProducer<[Contact]?, NSError>?
    func contactUpdateProducer(contactId contactId: String, weight: ContentWeight) -> SignalProducer<Contact?, NSError>?
    func deleteContact(contact: Contact)
    
}
