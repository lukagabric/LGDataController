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
    var noContentViewHidden: AnyProperty<Bool> { get }
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
    
    weak var loadingView: LGLoadingView!
    weak var noContentView: LGTextOverlayView!
    
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
        
        self.deleteBarButtonItem.rex_action <~ SignalProducer(value: CocoaAction(self.viewModel.deleteAction, input: ()))
        
        self.navigationItem.rightBarButtonItem = self.deleteBarButtonItem
        
        self.noContentView = LGTextOverlayView.attachContentUnavailableViewToView(self.view)
        self.noContentView.rex_hidden <~ self.viewModel.noContentViewHidden
        self.loadingView = LGLoadingView.attachToView(self.view, loadingViewModel: self.viewModel.loadingViewModel)

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
