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

    private let mutableLoadingContactData = MutableProperty<Bool>(false)

    public let loadingViewHidden: AnyProperty<Bool>
    private let mutableLoadingViewHidden = MutableProperty<Bool>(true)
    
    public let contentUnavailableViewHidden: AnyProperty<Bool>
    private let mutableContentUnavailableViewHidden = MutableProperty<Bool>(true)
    
    public let contentUnavailableText: AnyProperty<String>
    private let mutableContentUnavailableText = MutableProperty<String>("")
    
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

        self.isOffline = self.reachabilityService.isOffline

        self.deleteAction = Action(enabledIf: self.mutableDeleteButtonEnabled) { [weak self] _ in
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

            if !sself.mutableLoadingContactData.value && sself.contact.value == nil {
                sself.configureBindings()
            }
        }
    }
    
    func configureBindings() {
        let trueProducer = SignalProducer<Bool, NoError>(value: true)
        let nilContactProducer = SignalProducer<Contact?, NoError>(value: nil)

        let contactOrNilAndErrorProducer = self.dataService.producerForContactWithId(self.contactId, weight: .Full)
        let contactOrNilProducer = contactOrNilAndErrorProducer.flatMapError { _ in SignalProducer<Contact?, NoError>(value: nil) }
        let contactProducer = contactOrNilProducer.filter { $0 != nil }
        
        let loadingProducer = trueProducer.concat(contactOrNilProducer.map { _ in false})
        
        let contactDeletedEventProducer = contactProducer.flatMap(.Concat) { $0!.deleteProducer }
        let falseOnContactDeletedProducer = contactDeletedEventProducer.map { _ in false }
        
        let contactAvailableAfterLoad = contactOrNilProducer.map { $0 != nil }
        let contactAvailableProducer = contactAvailableAfterLoad.concat(falseOnContactDeletedProducer)
        let contactAvailableExceptUserDeleteActionProducer = contactAvailableProducer.takeUntil(self.deleteActionExecutedProducer)
        
        self.mutableContact <~ nilContactProducer.concat(contactProducer)
        self.mutableLoadingViewHidden <~ loadingProducer.map { !$0 }
        self.mutableLoadingContactData <~ loadingProducer
        self.mutableContentUnavailableViewHidden <~ loadingProducer.filter { $0 == true }.concat(contactAvailableExceptUserDeleteActionProducer)
        self.mutableContentUnavailableText <~ contactAvailableExceptUserDeleteActionProducer.combineLatestWith(self.isOffline.producer)
            .map { return $0.1 ? "You're offline." : "Content not available." }
        self.mutableDeleteButtonEnabled <~ loadingProducer.combineLatestWith(contactAvailableProducer).map { !$0 && $1 }
    }

}
