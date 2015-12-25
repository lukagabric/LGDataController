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
    
    public var loadingProducer: SignalProducer<Bool, NSError>!
    
    private let fetchedResultsController: NSFetchedResultsController

    private var previousSections: [NSFetchedResultsSectionInfo]?
    
    //MARK: - Init
    
    init(fetchedResultsController: NSFetchedResultsController, updateProducer: SignalProducer<[T]?, NSError>?) {
        self.fetchedResultsController = fetchedResultsController
        
        (self.modelChangedProducer, self.modelChangedObserver) = SignalProducer<LGModelChange, NoError>.buffer(1)
        (self.fetchedObjectsProducer, self.fetchedObjectsObserver) = SignalProducer<[T]?, NoError>.buffer(1)
        
        super.init()

        self.configureFRC()
        
        if self.fetchedResultsController.fetchedObjects?.count > 0 {
            self.loadingProducer = SignalProducer(value: true)
        }
        else if let updateProducer = updateProducer {
            self.loadingProducer = updateProducer.map { objects in objects?.count > 0 }
        }
        else {
            self.loadingProducer = SignalProducer(value: false)
        }
        
        let modelChange = LGModelChange(previousSections: nil, sections: self.fetchedResultsController.sections)
        self.sendModelChange(modelChange)
        self.sendFetchedObjects()
    }
    
    //MARK: - Configuration
    
    private func configureFRC() {
        self.fetchedResultsController.delegate = self
        try! self.fetchedResultsController.performFetch()
    }
    
    //MARK: - Signaling
    
    private func sendModelChange(modelChange: LGModelChange) {
        self.modelChangedObserver.sendNext(modelChange)
    }

    private func sendFetchedObjects() {
        let fetchedObjects = self.fetchedResultsController.fetchedObjects as? [T]
        self.fetchedObjectsObserver.sendNext(fetchedObjects?.count > 0 ? fetchedObjects : nil)
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
