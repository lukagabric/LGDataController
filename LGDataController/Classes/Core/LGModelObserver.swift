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
    
    public let modelChangedSignalProducer: SignalProducer<LGModelChange, NoError>
    private let modelChangedObserver: Observer<LGModelChange, NoError>
    
    public let fetchedObjectsSignalProducer: SignalProducer<[T]?, NoError>
    private let fetchedObjectsObserver: Observer<[T]?, NoError>
    
    public let refreshSignal: Signal<Void, NSError>?
    
    public let loadingSignalProducer: SignalProducer<Bool, NoError>
    private let loadingSignalObserver: Observer<Bool, NoError>
    
    private let fetchedResultsController: NSFetchedResultsController

    private var previousSections: [NSFetchedResultsSectionInfo]?
    
    //MARK: - Init
    
    init(fetchedResultsController: NSFetchedResultsController, refreshSignal: Signal<Void, NSError>?) {
        self.fetchedResultsController = fetchedResultsController

        self.refreshSignal = refreshSignal
        
        let (modelChangedSignalProducer, modelChangedObserver) = SignalProducer<LGModelChange, NoError>.buffer(1)
        self.modelChangedSignalProducer = modelChangedSignalProducer
        self.modelChangedObserver = modelChangedObserver
        
        let (fetchedObjectsSignalProducer, fetchedObjectsObserver) = SignalProducer<[T]?, NoError>.buffer(1)
        self.fetchedObjectsSignalProducer = fetchedObjectsSignalProducer
        self.fetchedObjectsObserver = fetchedObjectsObserver

        let (loadingSignalProducer, loadingSignalObserver) = SignalProducer<Bool, NoError>.buffer(1)
        self.loadingSignalProducer = loadingSignalProducer
        self.loadingSignalObserver = loadingSignalObserver
        
        super.init()

        self.configureLoadingSignalProducer()
        self.configureFRC()
        
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
        if let refreshSignal = self.refreshSignal {
            self.loadingSignalObserver.sendNext(true)
            
            refreshSignal.observe { [weak self] _ in
                self?.loadingSignalObserver.sendNext(false)
                self?.loadingSignalObserver.sendCompleted()
            }
        }
        else {
            self.loadingSignalObserver.sendNext(false)
            self.loadingSignalObserver.sendCompleted()
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
