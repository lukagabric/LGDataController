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
    private var mutableDeleteButtonEnabled = MutableProperty<Bool>(false)
    
    private let contactId: String
    public let contact: AnyProperty<Contact?>
    private let mutableContact = MutableProperty<Contact?>(nil)

    public var deleteAction: Action<Void, Void, NoError>!
    private var deleteActionExecutedProducer: SignalProducer<Void, NoError>!
    
    public var loadingViewModel: LoadingViewModelType!
    
    private var contactProducer: SignalProducer<Contact?, NSError> {
        return self.dataService.producerForContactWithId(contactId, weight: .Full)
    }
    
    init(dependencies: ContactsModuleDependencies, contactId: String) {
        self.dataService = dependencies.contactsDataService
        self.navigationService = dependencies.contactsNavigationService
        
        self.contactId = contactId
        self.contact = AnyProperty(self.mutableContact)

        self.loadingViewModel = LoadingViewModel(reachabilityService: dependencies.reachabilityService) { [weak self] in
            return self?.contactProducer.map { $0 != nil } ?? SignalProducer.empty
        }
        self.loadingViewModel.modelLoadedProducer.startWithCompleted { [weak self] in
            self?.configureBindings()
        }

        self.deleteAction = Action(enabledIf: self.mutableDeleteButtonEnabled) { [weak self] _ in
            self?.contact.producer.startWithNext { [weak self] contact in
                guard let sself = self, contact = contact else { return }
                
                sself.dataService.deleteContact(contact)
                sself.navigationService.popView(animated: true)
            }
            
            return SignalProducer.empty
        }
        self.deleteActionExecutedProducer = self.deleteAction.executing.producer.skip(1).map { _ in () }
    }
    
    func configureBindings() {
        let falseProducer = SignalProducer<Bool, NoError>(value: false)
        let nilContactProducer = SignalProducer<Contact?, NoError>(value: nil)
        
        let contactOrNilAndErrorProducer = self.contactProducer
        let contactOrNilProducer = contactOrNilAndErrorProducer.flatMapError { _ in SignalProducer<Contact?, NoError>(value: nil) }
        let contactProducer = contactOrNilProducer.filter { $0 != nil }
        
        let contactDeletedEventProducer = contactProducer.flatMap(.Concat) { $0!.deleteProducer }
        let falseOnContactDeletedProducer = contactDeletedEventProducer.map { _ in false }
        
        let contactAvailableAfterLoad = contactOrNilProducer.map { $0 != nil }
        self.mutableContact <~ nilContactProducer.concat(contactProducer)
        self.mutableDeleteButtonEnabled <~ falseProducer.concat(contactAvailableAfterLoad).concat(falseOnContactDeletedProducer)
        
//        self.takeUntilProducer = self.deleteActionExecutedProducer
//        self.modelProducer = contactBoolAndErrorProducer
//        self.modelBecameUnavailableProducer = contactDeletedEventProducer
    }
    
}
