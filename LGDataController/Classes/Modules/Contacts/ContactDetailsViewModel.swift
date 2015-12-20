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
    
    private let dataService: ContactsDataServiceType
    private let navigationService: ContactsNavigationServiceType
    private let reachabilityService: ReachabilityServiceType
    
    public let contact: AnyProperty<Contact?>
    private let mutableContact = MutableProperty<Contact?>(nil)

    private let loadingContactData = MutableProperty<Bool>(false)

    public let loadingViewHidden: AnyProperty<Bool>
    private let mutableLoadingViewHidden = MutableProperty<Bool>(true)
    
    public let contentUnavailableViewHidden: AnyProperty<Bool>
    private let mutableContentUnavailableViewHidden = MutableProperty<Bool>(true)
    
    public let contentUnavailableText: AnyProperty<String>
    private let mutableContentUnavailableText = MutableProperty<String>("")
    
    private var deleteButtonEnabled: AnyProperty<Bool>
    private var mutableDeleteButtonEnabled = MutableProperty<Bool>(false)
    
    public var deleteAction: Action<Void, Void, NoError>!
    private var deleteActionExecutedProducer: SignalProducer<Void, NoError>!
    
    private let isOffline: MutableProperty<Bool>
    
    init(dependencies: ContactsModuleDependencies, contactId: String) {
        self.dataService = dependencies.contactsDataService
        self.navigationService = dependencies.contactsNavigationService
        self.reachabilityService = dependencies.reachabilityService
        
        self.contactId = contactId
        
        self.contact = AnyProperty(self.mutableContact)
        self.loadingViewHidden = AnyProperty(self.mutableLoadingViewHidden)
        self.contentUnavailableViewHidden = AnyProperty(self.mutableContentUnavailableViewHidden)
        self.contentUnavailableText = AnyProperty(self.mutableContentUnavailableText)
        self.deleteButtonEnabled = AnyProperty(self.mutableDeleteButtonEnabled)

        self.isOffline = self.reachabilityService.isOffline

        self.deleteAction = Action(enabledIf: self.deleteButtonEnabled) { [weak self] _ in
            self?.contact.producer.startWithNext { [weak self] contact in
                guard let sself = self, contact = contact else { return }
                
                sself.dataService.deleteContact(contact)
                sself.navigationService.popView(animated: true)
            }
            
            return SignalProducer.empty
        }
        self.deleteActionExecutedProducer = self.deleteAction.executing.producer.skip(1).map { _ in () }
        
        self.configureBindings()

        self.reachabilityService.reachability.producer
            .filter { reachability in reachability.isReachable() }
            .startWithNext { [weak self] reachability in
            guard let sself = self else { return }

            if !sself.loadingContactData.value && sself.contact.value == nil {
                sself.configureBindings()
            }
        }
    }
    
    func configureBindings() {
        let contactProducer = self.dataService.producerForContactWithId(self.contactId, weight: .Full)
        
        self.mutableContact <~ contactProducer.ignoreError()
        
        let loadingHiddenProducer = lg_loadingHiddenProducerFrom(contactProducer)
        self.mutableLoadingViewHidden <~ loadingHiddenProducer
        
        self.loadingContactData <~ lg_loadingProducerFrom(contactProducer)
        
        let trueProducer = SignalProducer<Bool, NoError>(value: true)
        let contactOrNilProducer = contactProducer.flatMapError { _ in SignalProducer<Contact?, NoError>(value: nil) }
        let contactAvailableBoolProducer = contactOrNilProducer.map { contact in contact != nil }
        let contactDeletedEventProducer = contactOrNilProducer.flatMap(.Concat) { contact in contact?.deleteProducer ?? SignalProducer.empty }
        let falseOnContactDeletedProducer = contactDeletedEventProducer.map { _ in false }
        let contentUnavailableProducer = contactAvailableBoolProducer.concat(falseOnContactDeletedProducer)
        let contentUnavailableExceptUserDeleteActionProducer = trueProducer.concat(contentUnavailableProducer).takeUntil(self.deleteActionExecutedProducer)
        self.mutableContentUnavailableViewHidden <~ contentUnavailableExceptUserDeleteActionProducer
        
        self.mutableContentUnavailableText <~ contentUnavailableExceptUserDeleteActionProducer.combineLatestWith(self.isOffline.producer)
            .map { return $0.1 ? "You're offline." : "Content not available." }

        self.mutableDeleteButtonEnabled <~ loadingHiddenProducer.combineLatestWith(contentUnavailableProducer).map { $0 && $1 }
    }

}
