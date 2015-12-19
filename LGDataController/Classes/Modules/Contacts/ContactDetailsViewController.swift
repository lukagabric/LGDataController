//
//  ContactDetailsViewController.swift
//  LGDataController
//
//  Created by Luka Gabric on 15/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit
import ReactiveCocoa

public protocol ContactDetailsViewModelType {
    
    var contactProducer: SignalProducer<Contact?, NSError>! { get }
    var loadingHiddenProducer: SignalProducer<Bool, NoError>! { get }
    var contentUnavailableHiddenProducer: SignalProducer<Bool, NoError>! { get }
    var deleteAction: Action<Void, Void, NoError>! { get }

}

public class ContactDetailsViewController: UIViewController {
    
    private var viewModel: ContactDetailsViewModelType!
    
    private var barButtonAction: CocoaAction!
    
    @IBOutlet weak var guidLabel: UILabel!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    
    var deleteBarButtonItem: UIBarButtonItem!
    
    //MARK: - Init
    
    init(viewModel: ContactDetailsViewModelType) {
        self.viewModel = viewModel
        self.barButtonAction = CocoaAction(viewModel.deleteAction, input: ())

        super.init(nibName: nil, bundle: nil)
        
//        self.simulateUnrelatedDeleteOfCurrentObject()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - View Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.deleteBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash, target: self.barButtonAction, action: CocoaAction.selector)
        self.navigationItem.rightBarButtonItem = self.deleteBarButtonItem
        
        self.edgesForExtendedLayout = .None
        
        LGLoadingView.attachToView(self.view).rac_hidden <~ self.viewModel.loadingHiddenProducer
        LGTextOverlayView.contentUnavailableViewAttachToView(self.view).rac_hidden <~ self.viewModel.contentUnavailableHiddenProducer

        self.viewModel.contactProducer.startWithNext { [weak self] contact in
            guard let contact = contact, sself = self else { return }

            sself.guidLabel.text = contact.guid
            sself.firstNameLabel.rac_text <~ contact.firstNameProducer
            sself.lastNameLabel.rac_text <~ contact.lastNameProducer
            sself.companyLabel.rac_text <~ contact.companyProducer
            sself.emailLabel.rac_text <~ contact.emailProducer
            sself.weightLabel.rac_text <~ contact.weightProducer            
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
