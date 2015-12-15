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
    
}

public protocol ContactsNavigationServiceType {
    
    func pushContactDetails(contactId contactId: String)
    
}
