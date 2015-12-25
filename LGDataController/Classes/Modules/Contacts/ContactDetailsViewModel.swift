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
    
    private let dataService: ContactsDataServiceType
    private let navigationService: ContactsNavigationServiceType
    private var deleteButtonEnabled = MutableProperty<Bool>(false)
    
    private let contactId: String
    public let contact: AnyProperty<Contact?>
    private let mContact = MutableProperty<Contact?>(nil)

    public var deleteAction: Action<Void, Void, NoError>!
    private var deleteActionExecutedProducer: SignalProducer<Void, NoError>!
    
    public var loadingViewModel: LoadingViewModelType!
    
    init(dependencies: ContactsModuleDependencies, contactId: String) {
        self.dataService = dependencies.contactsDataService
        self.navigationService = dependencies.contactsNavigationService
        
        self.contactId = contactId
        self.contact = AnyProperty(self.mContact)

        self.loadingViewModel = LoadingViewModel(reachabilityService: dependencies.reachabilityService) { [weak self] in
            return self?.configuredLoadingProducer() ?? SignalProducer.empty
        }

        self.deleteAction = Action(enabledIf: self.deleteButtonEnabled) { [weak self] _ in
            self?.contact.producer.startWithNext { [weak self] contact in
                guard let sself = self, contact = contact else { return }
                
                sself.dataService.deleteContact(contact)
                sself.navigationService.popView(animated: true)
            }
            
            return SignalProducer.empty
        }
        self.deleteActionExecutedProducer = self.deleteAction.executing.producer.skip(1).map { _ in () }
    }
    
    func configuredLoadingProducer() -> SignalProducer<Bool, NSError> {
        let contactUpdateProducer = self.dataService.producerForContactWithId(contactId, weight: .Full)
        
        let contactOrNilProducer = contactUpdateProducer.flatMapError { _ in SignalProducer<Contact?, NoError>(value: nil) }
        let contactProducer = contactOrNilProducer.filter { $0 != nil }

        let contactDeletedEventProducer = contactProducer.flatMap(.Concat) { $0!.deleteProducer }
        let falseOnContactDeletedProducer = contactDeletedEventProducer.map { _ in false }
        
        let contactAvailableAfterLoad = contactOrNilProducer.map { $0 != nil }
        let falseProducer = SignalProducer<Bool, NoError>(value: false)
        let nilProducer = SignalProducer<Contact?, NoError>(value: nil)
        self.mContact <~ nilProducer.concat(contactProducer)
        self.deleteButtonEnabled <~ falseProducer.concat(contactAvailableAfterLoad).concat(falseOnContactDeletedProducer)
        
        return contactUpdateProducer.map { $0 != nil }
    }
    
}
