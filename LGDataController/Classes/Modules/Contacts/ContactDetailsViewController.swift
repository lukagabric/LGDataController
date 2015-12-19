//
//  ContactDetailsViewController.swift
//  LGDataController
//
//  Created by Luka Gabric on 15/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Rex

public protocol ContactDetailsViewModelType {
    
    var contactProducer: SignalProducer<Contact?, NSError>! { get }
    var loadingHiddenProducer: SignalProducer<Bool, NoError>! { get }
    var contentUnavailableHiddenProducer: SignalProducer<Bool, NoError>! { get }
    var deleteAction: Action<Void, Void, NoError>! { get }

}

public class ContactDetailsViewController: UIViewController {
    
    private var viewModel: ContactDetailsViewModelType!
    
    @IBOutlet weak var guidLabel: UILabel!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    
    @IBOutlet var deleteBarButtonItem: UIBarButtonItem!
    
    //MARK: - Init
    
    init(viewModel: ContactDetailsViewModelType) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
        
//        self.simulateUnrelatedDeleteOfCurrentObject()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - View Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        self.edgesForExtendedLayout = .None
        
        self.deleteBarButtonItem.rex_action <~ SignalProducer(value: CocoaAction(self.viewModel.deleteAction, input: ()))
        
        self.navigationItem.rightBarButtonItem = self.deleteBarButtonItem
        
        LGLoadingView.attachToView(self.view).rex_hidden <~ self.viewModel.loadingHiddenProducer
        LGTextOverlayView.contentUnavailableViewAttachToView(self.view).rex_hidden <~ self.viewModel.contentUnavailableHiddenProducer

        self.viewModel.contactProducer.startWithNext { [weak self] contact in
            guard let contact = contact, sself = self else { return }

            sself.guidLabel.text = contact.guid
            sself.firstNameLabel.rex_text <~ contact.firstNameProducer
            sself.lastNameLabel.rex_text <~ contact.lastNameProducer
            sself.companyLabel.rex_text <~ contact.companyProducer
            sself.emailLabel.rex_text <~ contact.emailProducer
            sself.weightLabel.rex_text <~ contact.weightProducer            
        }
    }

    //MARK: -
    
    func simulateUnrelatedDeleteOfCurrentObject() {
//        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
//        dispatch_after(delayTime, dispatch_get_main_queue()) { [weak self] in
//            guard let contact = self?.viewModel.contact.value else { return }
//            contact.managedObjectContext?.deleteObject(contact)
//            try! contact.managedObjectContext?.save()
//        }
    }

}
