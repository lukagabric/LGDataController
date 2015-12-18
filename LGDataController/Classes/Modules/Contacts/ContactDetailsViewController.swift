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
    
    var contact: MutableProperty<Contact?> { get }
    var updateProducer: SignalProducer<Contact?, NSError>? { get }
    var deleteAction: Action<Void, Void, NoError>! { get }

}

public class ContactDetailsViewController: UIViewController {
    
    private var viewModel: ContactDetailsViewModelType!
    
    private var barButtonAction: CocoaAction!
    
    private var contact: Contact? {
        return self.viewModel.contact.value
    }
    
    @IBOutlet weak var guidLabel: UILabel!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    
    //MARK: - Init
    
    init(viewModel: ContactDetailsViewModelType) {
        self.viewModel = viewModel
        self.barButtonAction = CocoaAction(viewModel.deleteAction, input: ())

        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - View Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash, target: self.barButtonAction, action: CocoaAction.selector)
        
        self.edgesForExtendedLayout = .None
        
        if self.contact == nil || self.contact!.contentWeight != .Full {
            LGLoadingView.attachToView(self.view, updateProducer: self.viewModel.updateProducer)
        }
        
        self.viewModel.contact.producer.startWithNext { [weak self] contact in
            guard let contact = contact, sself = self else { return }

            sself.guidLabel.text = contact.guid
            sself.firstNameLabel.rac_text <~ contact.firstNameProducer
            sself.lastNameLabel.rac_text <~ contact.lastNameProducer
            sself.companyLabel.rac_text <~ contact.companyProducer
            sself.emailLabel.rac_text <~ contact.emailProducer
            sself.weightLabel.rac_text <~ contact.weightProducer
            
            contact.deleteProducer.startWithNext { [weak self] in
                guard let view = self?.view else { return }
                LGTextOverlayView.contentUnavailableView(frame: view.bounds, addedToView: view)
            }
        }
    }

    //MARK: -

}
