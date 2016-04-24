//
//  ContactsDependencies.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

public protocol ContactsDependencies {
    
    var dataController: DataController { get }
    var contactsDataService: ContactsDataService { get }
    var contactsNavigationService: ContactsNavigationServiceType { get }
    var reachabilityService: ReachabilityService { get }
    
}

public protocol ContactsNavigationServiceType {
    
    func pushContactDetails(contactId contactId: String)
    func popView(animated animated: Bool)
    
}
