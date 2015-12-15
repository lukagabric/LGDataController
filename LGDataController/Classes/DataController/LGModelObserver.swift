//
//  LGModelObserver.swift
//  LGDataController
//
//  Created by Luka Gabric on 22/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa
import CoreData

public class LGModelChange {
    
    public let previousSections: [NSFetchedResultsSectionInfo]?
    public let sections: [NSFetchedResultsSectionInfo]?
    
    init(previousSections: [NSFetchedResultsSectionInfo]?, sections: [NSFetchedResultsSectionInfo]?) {
        self.previousSections = previousSections
        self.sections = sections
    }
    
}

public class LGModelObserver<T: AnyObject>: NSObject, NSFetchedResultsControllerDelegate {
    
    public let modelChangedProducer: SignalProducer<LGModelChange, NoError>
    private let modelChangedObserver: Observer<LGModelChange, NoError>
    
    public let fetchedObjectsProducer: SignalProducer<[T]?, NoError>
    private let fetchedObjectsObserver: Observer<[T]?, NoError>
    
    public let refreshProducer: SignalProducer<Void, NSError>?
    
    public let loadingProducer: SignalProducer<Bool, NoError>
    private let loadingObserver: Observer<Bool, NoError>
    
    private let fetchedResultsController: NSFetchedResultsController

    private var previousSections: [NSFetchedResultsSectionInfo]?
    
    //MARK: - Init
    
    init(fetchedResultsController: NSFetchedResultsController, updateProducer: SignalProducer<[T]?, NSError>?) {
        self.fetchedResultsController = fetchedResultsController

        self.refreshProducer = updateProducer?.map { _ in () }
        
        (self.modelChangedProducer, self.modelChangedObserver) = SignalProducer<LGModelChange, NoError>.buffer(1)
        (self.fetchedObjectsProducer, self.fetchedObjectsObserver) = SignalProducer<[T]?, NoError>.buffer(1)
        (self.loadingProducer, self.loadingObserver) = SignalProducer<Bool, NoError>.buffer(1)
        
        super.init()

        self.configureFRC()
        self.configureLoadingSignalProducer()
        
        let modelChange = LGModelChange(previousSections: nil, sections: self.fetchedResultsController.sections)
        self.sendModelChange(modelChange)
        self.sendFetchedObjects()
    }
    
    //MARK: - Configuration
    
    private func configureFRC() {
        self.fetchedResultsController.delegate = self
        try! self.fetchedResultsController.performFetch()
    }
    
    private func configureLoadingSignalProducer() {
        if let
            refreshProducer = self.refreshProducer,
            count = self.fetchedResultsController.fetchedObjects?.count where count == 0 {
                self.loadingObserver.sendNext(true)
                
                refreshProducer.start { [weak self] event in
                    if event.isTerminating {
                        self?.loadingObserver.sendNext(false)
                        self?.loadingObserver.sendCompleted()
                    }
                }
        }
        else {
            self.loadingObserver.sendNext(false)
            self.loadingObserver.sendCompleted()
        }
    }
    
    //MARK: - Signaling
    
    private func sendModelChange(modelChange: LGModelChange) {
        self.modelChangedObserver.sendNext(modelChange)
    }

    private func sendFetchedObjects() {
        let fetchedObjects = self.fetchedResultsController.fetchedObjects as? [T]
        self.fetchedObjectsObserver.sendNext(fetchedObjects)
    }
    
    //MARK: - NSFetchedResultsControllerDelegate
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.previousSections = controller.sections
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        let modelChange = LGModelChange(previousSections: self.previousSections, sections: controller.sections)
        self.previousSections = nil
        
        self.sendModelChange(modelChange)
        self.sendFetchedObjects()
    }
    
    //MARK: -
    
}
