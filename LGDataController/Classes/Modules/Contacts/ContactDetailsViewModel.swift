//
//  ContactDetailsViewModel.swift
//  LGDataController
//
//  Created by Luka Gabric on 15/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa

public class ContactDetailsViewModel {

    //MARK: - Vars
    
    private let contactId: String

    public let contactModelObserver: ModelObserver<Contact>
    var contactProducer: SignalProducer<Contact?, NoError> {
        return self.contactModelObserver.fetchedObjectsProducer.map { contacts in contacts?.first }
    }

    public var deleteAction: Action<Void, Void, NoError>!
    private var deleteActionExecutedProducer: SignalProducer<Void, NoError>!
    private var deleteButtonEnabled = MutableProperty<Bool>(false)
    
    public var noContentViewHiddenProducer: SignalProducer<Bool, NoError>!

    public var loadingViewModel: LoadingViewModel!

    //MARK: - Dependencies
    
    private let dataService: ContactsDataService
    private let navigationService: ContactsNavigationServiceType
    
    init(dependencies: ContactsDependencies, contactId: String) {
        self.dataService = dependencies.contactsDataService
        self.navigationService = dependencies.contactsNavigationService
        
        self.contactId = contactId
        self.contactModelObserver = self.dataService.contactModelObserver(contactId: self.contactId)
        
        let contactAvailable = self.contactProducer.map { $0 != nil }
        let contactDeletedEventProducer = contactProducer.flatMap(.Latest) { $0?.deleteProducer ?? SignalProducer.empty }
        let falseOnContactDeletedProducer = contactDeletedEventProducer.map { _ in false }
        let falseProducer = SignalProducer<Bool, NoError>(value: false)

        self.deleteAction = Action(enabledIf: self.deleteButtonEnabled) { [weak self] _ in
            guard let sself = self else { return SignalProducer.empty }

            sself.contactProducer.startWithNext { [weak self] contact in
                guard let sself = self, contact = contact else { return }
                
                sself.dataService.deleteContact(contact)
                sself.navigationService.popView(animated: true)
            }
            
            return SignalProducer.empty
        }
        self.deleteActionExecutedProducer = self.deleteAction.executing.producer.skip(1).map { _ in () }
        let deleteButtonActionProducer = self.deleteAction.executing.producer.skip(1).map { _ in () }
        self.noContentViewHiddenProducer = contactAvailable.concat(falseOnContactDeletedProducer).takeUntil(deleteButtonActionProducer)
        self.deleteButtonEnabled <~ falseProducer.concat(contactAvailable).concat(falseOnContactDeletedProducer)
        
        self.loadingViewModel = LoadingViewModel(reachabilityService: dependencies.reachabilityService) { [weak self] in
            guard let
                sself = self,
                updateProducer = sself.dataService.contactUpdateProducer(contactId: sself.contactId)
                else { return nil }
            
            let objectProducer = sself.contactModelObserver.fetchedObjectsProducer
            return lg_loadingViewProducer(objectProducer: objectProducer, updateProducer: updateProducer.lg_voidValue)
        }
    }
    
}
