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
    public var loadingHiddenProducer: SignalProducer<Bool, NoError>!
    public var contentUnavailableHiddenProducer: SignalProducer<Bool, NoError>!
    
    private let dataService: ContactsDataServiceType
    private let navigationService: ContactsNavigationServiceType
    
    public var deleteAction: Action<(), (), NoError>!
    
    init(dependencies: ContactsModuleDependencies, contactId: String) {
        self.dataService = dependencies.contactsDataService
        self.navigationService = dependencies.contactsNavigationService

        self.contactProducer = self.dataService.producerForContactWithId(contactId, weight: .Full)
        self.loadingHiddenProducer = loadingHiddenProducerFrom(self.contactProducer)

        self.deleteAction = Action { [weak self] in
            self?.contactProducer.startWithNext { [weak self] contact in
                guard let sself = self, contact = contact else { return }
                
                sself.dataService.deleteContact(contact)
                sself.navigationService.popView(animated: true)
            }
            
            return SignalProducer.empty
        }

        let firstHiddenProducer = SignalProducer<Bool, NoError>(value: true)
        let hiddenAfterRefreshProducer = self.contactProducer
            .flatMapError { _ in SignalProducer<Contact?, NoError>(value: nil) }
            .map { contact in contact != nil }
        let hiddenAfterDeleteProducer = self.contactProducer
            .flatMapError { _ in return SignalProducer(value: nil) }
            .flatMap(.Concat) { contact in contact?.deleteProducer ?? SignalProducer.empty }
            .map { _ in false }
        
        let deleteActionExecutedProducer = self.deleteAction.executing.producer.skip(1).map { _ in () }

        self.contentUnavailableHiddenProducer = firstHiddenProducer
            .concat(hiddenAfterRefreshProducer)
            .concat(hiddenAfterDeleteProducer)
            .takeUntil(deleteActionExecutedProducer)
        
    }
        
}
