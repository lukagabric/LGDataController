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
    
    var contact: AnyProperty<Contact?> { get }
    var loadingViewModel: LoadingViewModelType! { get }
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
    
    weak var contentUnavailableView: LGTextOverlayView!
    weak var loadingView: LGLoadingView!
    
    
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
        self.navigationItem.rightBarButtonItem = self.deleteBarButtonItem
        
        self.loadingView = LGLoadingView.attachToView(self.view)
        self.loadingView.rex_hidden <~ self.viewModel.loadingViewModel.loadingViewHidden
        self.contentUnavailableView = LGTextOverlayView.attachToView(self.view)
        self.contentUnavailableView.rex_hidden <~ self.viewModel.loadingViewModel.contentUnavailableViewHidden
        self.contentUnavailableView.rac_text <~ self.viewModel.loadingViewModel.contentUnavailableText

        self.viewModel.contact.producer.startWithNext { [weak self] contact in
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
    
}
