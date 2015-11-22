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

public class NoValue {
    
}

public class LGModelChange {
    
    public let previousSections: [NSFetchedResultsSectionInfo]?
    public let sections: [NSFetchedResultsSectionInfo]?
    
    init(previousSections: [NSFetchedResultsSectionInfo]?, sections: [NSFetchedResultsSectionInfo]?) {
        self.previousSections = previousSections
        self.sections = sections
    }
    
}

public class LGModelObserver: NSObject, NSFetchedResultsControllerDelegate {
    
    public let modelChangedSignal: Signal<LGModelChange, NSError>
    private let modelChangedObserver: Observer<LGModelChange, NSError>
    
    public let refreshSignal: Signal<Void, NSError>?
    
    private let fetchedResultsController: NSFetchedResultsController

    private var previousSections: [NSFetchedResultsSectionInfo]?
    
    init(fetchedResultsController: NSFetchedResultsController, refreshSignal: Signal<Void, NSError>?) {
        self.fetchedResultsController = fetchedResultsController
        self.refreshSignal = refreshSignal
        
        let (modelChangedSignal, modelChangedObserver) = Signal<LGModelChange, NSError>.pipe()
        self.modelChangedSignal = modelChangedSignal
        self.modelChangedObserver = modelChangedObserver
        
        super.init()
        
        self.fetchedResultsController.delegate = self
        try! self.fetchedResultsController.performFetch()

        let modelChange = LGModelChange(previousSections: nil, sections: self.fetchedResultsController.sections)
        self.modelChangedObserver.sendNext(modelChange)
    }
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.previousSections = controller.sections
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        let modelChange = LGModelChange(previousSections: self.previousSections, sections: controller.sections)
        self.previousSections = nil
        self.modelChangedObserver.sendNext(modelChange)
    }
    
}
