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
    private var mutableDeleteButtonEnabled = MutableProperty<Bool>(false)
    
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
        let reachabilityService = dependencies.reachabilityService
        
        self.contactId = contactId
        
        self.contact = AnyProperty(self.mutableContact)

        self.loadingViewModel = LoadingViewModel(reachabilityService: reachabilityService) {
            return self.contactProducer.map { $0 != nil }
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
        
        self.loadingViewModel.modelLoaded.producer.filter { $0 == true }.startWithNext { [weak self] _ in
            self?.configureBindings()
        }
    }
    
    func configureBindings() {
        let trueProducer = SignalProducer<Bool, NoError>(value: true)
//        let falseProducer = SignalProducer<Bool, NoError>(value: false)
        let nilContactProducer = SignalProducer<Contact?, NoError>(value: nil)
        
        let contactOrNilAndErrorProducer = self.contactProducer
//        let contactBoolAndErrorProducer = contactOrNilAndErrorProducer.map { contact in contact != nil }
        let contactOrNilProducer = contactOrNilAndErrorProducer.flatMapError { _ in SignalProducer<Contact?, NoError>(value: nil) }
        let contactProducer = contactOrNilProducer.filter { $0 != nil }
        
        let loadingProducer = trueProducer.concat(contactOrNilProducer.map { _ in false})
        
        let contactDeletedEventProducer = contactProducer.flatMap(.Concat) { $0!.deleteProducer }
        let falseOnContactDeletedProducer = contactDeletedEventProducer.map { _ in false }
//        let firstFalseThenTrueOnContactDeletedProducer = falseProducer.concat(contactDeletedEventProducer.map { _ in true })
        
        let contactAvailableAfterLoad = contactOrNilProducer.map { $0 != nil }
        let contactAvailableProducer = contactAvailableAfterLoad.concat(falseOnContactDeletedProducer)
//        let contactAvailableExceptUserDeleteActionProducer = contactAvailableProducer.takeUntil(self.deleteActionExecutedProducer)
        
        self.mutableContact <~ nilContactProducer.concat(contactProducer)
//        self.mutableLoadingViewHidden <~ loadingProducer.map { !$0 }
//        self.mutableContentUnavailableViewHidden <~ loadingProducer.filter { $0 == true }.concat(contactAvailableExceptUserDeleteActionProducer)
//        self.mutableContentUnavailableText <~ self.isOffline.producer.combineLatestWith(firstFalseThenTrueOnContactDeletedProducer)
//            .map { return $0 && !$1 ? "You're offline." : "Content not available." }
        
        self.mutableDeleteButtonEnabled <~ loadingProducer.combineLatestWith(contactAvailableProducer).map { !$0 && $1 }
        
//        self.takeUntilProducer = self.deleteActionExecutedProducer
//        self.modelProducer = contactBoolAndErrorProducer
//        self.modelBecameUnavailableProducer = contactDeletedEventProducer
    }
    
}
