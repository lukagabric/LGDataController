//
//  ContactDetailsViewModel.swift
//  LGDataController
//
//  Created by Luka Gabric on 15/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

public class ContactDetailsViewModel: BaseViewModel<Contact>, ContactDetailsViewModelType {
    
    private let contactId: String
    
    private let dataService: ContactsDataServiceType
    private let navigationService: ContactsNavigationServiceType
    private var mutableDeleteButtonEnabled = MutableProperty<Bool>(false)
    
    public var deleteAction: Action<Void, Void, NoError>!
    private var deleteActionExecutedProducer: SignalProducer<Void, NoError>!
    
    init(dependencies: ContactsModuleDependencies, contactId: String) {
        self.dataService = dependencies.contactsDataService
        self.navigationService = dependencies.contactsNavigationService
        let reachabilityService = dependencies.reachabilityService
        
        self.contactId = contactId
        
        super.init(reachabilityService: reachabilityService)

        self.deleteAction = Action(enabledIf: self.mutableDeleteButtonEnabled) { [weak self] _ in
            self?.model.producer.startWithNext { [weak self] contact in
                guard let sself = self, contact = contact else { return }
                
                sself.dataService.deleteContact(contact)
                sself.navigationService.popView(animated: true)
            }
            
            return SignalProducer.empty
        }
        self.deleteActionExecutedProducer = self.deleteAction.executing.producer.skip(1).map { _ in () }
        self.configureBindings()
    }
    
    override func configureBindings() {
        self.takeUntilProducer = self.deleteActionExecutedProducer
        
        self.modelProducer = dataService.producerForContactWithId(contactId, weight: .Full)
        
        let trueProducer = SignalProducer<Bool, NoError>(value: true)
        
        let contactOrNilProducer = self.modelProducer.flatMapError { _ in SignalProducer<Contact?, NoError>(value: nil) }
        let contactProducer = contactOrNilProducer.filter { $0 != nil }
        let loadingProducer = trueProducer.concat(contactOrNilProducer.map { _ in false})
        
        let contactDeletedEventProducer = contactProducer.flatMap(.Concat) { $0!.deleteProducer }
        let falseOnContactDeletedProducer = contactDeletedEventProducer.map { _ in false }

        let contactAvailableAfterLoad = contactOrNilProducer.map { $0 != nil }
        let contactAvailableProducer = contactAvailableAfterLoad.concat(falseOnContactDeletedProducer)

        self.mutableDeleteButtonEnabled <~ loadingProducer.combineLatestWith(contactAvailableProducer).map { !$0 && $1 }
    }
    
}
