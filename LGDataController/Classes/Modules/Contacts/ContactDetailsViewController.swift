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

}

public class ContactDetailsViewController: UIViewController {
    
    private var viewModel: ContactDetailsViewModelType!
    
    @IBOutlet weak var guidLabel: UILabel!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    //MARK: - Init
    
    init(viewModel: ContactDetailsViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - View Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = .None
        
        LGLoadingView.attachToView(self.view, entity: self.viewModel.contact.value, updateProducer: self.viewModel.updateProducer)
        
        self.viewModel.contact.producer.startWithNext { [weak self] contact in
            guard let contact = contact, sself = self else { return }

            sself.guidLabel.text = contact.guid
            sself.firstNameLabel.rac_text <~ contact.firstNameProducer
            sself.lastNameLabel.rac_text <~ contact.lastNameProducer
            sself.companyLabel.rac_text <~ contact.companyProducer
            sself.emailLabel.rac_text <~ contact.emailProducer
        }
    }

    //MARK: -

}
