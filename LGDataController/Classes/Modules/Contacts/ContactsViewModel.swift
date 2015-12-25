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
    
    public let contacts: AnyProperty<[Contact]?>
    private let mContacts = MutableProperty<[Contact]?>(nil)

    public let contactsTitle: AnyProperty<String>
    private let mContactsTitle = MutableProperty<String>("")

    public let noContentViewHidden: AnyProperty<Bool>
    private let mNoContentViewHidden = MutableProperty<Bool>(true)
    
    public var loadingViewModel: LoadingViewModelType!

    private let dataService: ContactsDataServiceType
    private var contactsModelObserver: LGModelObserver<Contact>!
    private let navigationService: ContactsNavigationServiceType
    
    //MARK: - Init

    init(dependencies: ContactsModuleDependencies) {
        self.dataService = dependencies.contactsDataService
        self.navigationService = dependencies.contactsNavigationService
        self.contacts = AnyProperty(self.mContacts)
        self.contactsTitle = AnyProperty(self.mContactsTitle)
        self.noContentViewHidden = AnyProperty(self.mNoContentViewHidden)
        
        self.loadingViewModel = LoadingViewModel(reachabilityService: dependencies.reachabilityService) { [weak self] in
            return self?.configuredLoadingProducer() ?? SignalProducer(value: ())
        }
    }
    
    //MARK: - Loading
    
    func configuredLoadingProducer() -> SignalProducer<Void, NSError> {
        self.contactsModelObserver = self.dataService.contactsModelObserver()

        let loadingProducer = self.contactsModelObserver.loadingProducer
        let fetchedObjectsProducer = self.contactsModelObserver.fetchedObjectsProducer
        
        self.mNoContentViewHidden <~ fetchedObjectsProducer.map { $0?.count > 0 }
        self.mContacts <~ fetchedObjectsProducer
        self.mContactsTitle <~ fetchedObjectsProducer.map { contacts -> String in
            guard let contacts = contacts else { return "0 contact(s)" }
            return "\(String(contacts.count)) contact(s)"
        }
        
        return loadingProducer
    }
    
    //MARK: - User Interaction
    
    public func didSelectContact(contact: Contact) {
        self.navigationService.pushContactDetails(contactId: contact.guid!)
    }
    
    //MARK: -

}
