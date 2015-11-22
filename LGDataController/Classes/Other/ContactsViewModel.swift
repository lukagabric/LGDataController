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
    
    public let contactsModelObserver: LGModelObserver
    
    init(dataController: LGDataController) {
        self.dataController = dataController
        
        let contactsInteractor = ContactsInteractor(dataController: dataController)
        self.contactsModelObserver = contactsInteractor.contactsModelObserver()
        
        self.contactsModelObserver.refreshSignal?.observeCompleted {
            print("update completed")
        }
    }
    
}
