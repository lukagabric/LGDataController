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
    
    private let contactId: String
    public let contact = MutableProperty<Contact?>(nil)
    
    init(dependencies: ContactsModuleDependencies, contactId: String) {
        self.contactId = contactId
    }
    
}
