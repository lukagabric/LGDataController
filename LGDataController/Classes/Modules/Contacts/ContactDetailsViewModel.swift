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
    
    public var contactProducer: SignalProducer<Contact?, NSError>!
    public var loadingViewHiddenProducer: SignalProducer<Bool, NoError>!
    public var contentUnavailableViewHiddenProducer: SignalProducer<Bool, NoError>!

    private var deleteButtonEnabled = MutableProperty<Bool>(false)
    private let dataService: ContactsDataServiceType
    private let navigationService: ContactsNavigationServiceType
    
    public var deleteAction: Action<Void, Void, NoError>!
    
    init(dependencies: ContactsModuleDependencies, contactId: String) {
        self.dataService = dependencies.contactsDataService
        self.navigationService = dependencies.contactsNavigationService

        self.deleteAction = Action(enabledIf: self.deleteButtonEnabled) { [weak self] _ in
            self?.contactProducer.startWithNext { [weak self] contact in
                guard let sself = self, contact = contact else { return }
                
                sself.dataService.deleteContact(contact)
                sself.navigationService.popView(animated: true)
            }
            
            return SignalProducer.empty
        }
        
        self.contactProducer = self.dataService.producerForContactWithId(contactId, weight: .Full)
        self.loadingViewHiddenProducer = loadingHiddenProducerFrom(self.contactProducer)

        let trueProducer = SignalProducer<Bool, NoError>(value: true)
        let contactOrNilProducer = self.contactProducer.flatMapError { _ in SignalProducer<Contact?, NoError>(value: nil) }
        let contactAvailableProducer = contactOrNilProducer.map { contact in contact != nil }
        let contactDeleteProducer = contactOrNilProducer.flatMap(.Concat) { contact in contact?.deleteProducer ?? SignalProducer.empty }
        let falseAfterContactDeletedProducer = contactDeleteProducer.map { _ in false }
        let deleteActionExecutedProducer = self.deleteAction.executing.producer.skip(1).map { _ in () }
        
        let contentUnavailableHiddenProducer = trueProducer
            .concat(contactAvailableProducer)
            .concat(falseAfterContactDeletedProducer)

        self.contentUnavailableViewHiddenProducer = contentUnavailableHiddenProducer.takeUntil(deleteActionExecutedProducer)
        
        self.deleteButtonEnabled <~ self.loadingViewHiddenProducer
            .combineLatestWith(contentUnavailableHiddenProducer)
            .map { $0 && $1 }
    }
    
}
