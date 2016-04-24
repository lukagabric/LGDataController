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
    
    public let contacts: AnyProperty<[Contact]?>
    public let contactsTitleProducer: SignalProducer<String, NoError>
    public let noContentViewHiddenProducer: SignalProducer<Bool, NoError>
    public var loadingViewModel: LoadingViewModel!
    private let contactsModelObserver: LGModelObserver<[Contact]>
    
    private let dataService: ContactsDataService
    private let navigationService: ContactsNavigationServiceType
    
    //MARK: - Init

    init(dependencies: ContactsDependencies) {
        self.dataService = dependencies.contactsDataService
        self.navigationService = dependencies.contactsNavigationService
        
        self.contactsModelObserver = self.dataService.contactsModelObserver()
        self.contacts = AnyProperty(initialValue: nil, producer: self.contactsModelObserver.fetchedObjectsProducer)
        self.contactsTitleProducer = self.contactsModelObserver.fetchedObjectsProducer.map { contacts -> String in
            guard let contacts = contacts else { return "0 contact(s)" }
            return "\(String(contacts.count)) contact(s)"
        }
        self.noContentViewHiddenProducer = self.contactsModelObserver.fetchedObjectsProducer.map { $0?.count > 0 }

        self.loadingViewModel = LoadingViewModel(reachabilityService: dependencies.reachabilityService) { [weak self] in
            guard let sself = self, updateProducer = sself.dataService.contactsUpdateProducer() else { return nil }
            let objectProducer = sself.contactsModelObserver.fetchedObjectsProducer
            return lg_loadingViewProducer(objectProducer: objectProducer, updateProducer: updateProducer.lg_voidValue)
        }
    }
    
    //MARK: - User Interaction
    
    public func didSelectContact(contact: Contact) {
        self.navigationService.pushContactDetails(contactId: contact.guid!)
    }
    
    //MARK: -

}
