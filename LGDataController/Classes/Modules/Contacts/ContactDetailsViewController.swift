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

public class ContactDetailsViewController: UIViewController {
    
    private var viewModel: ContactDetailsViewModel
    
    @IBOutlet weak var guidLabel: UILabel!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet var deleteBarButtonItem: UIBarButtonItem!
    
    weak var loadingView: LoadingView!
    weak var noContentView: TextOverlayView!
    
    //MARK: - Init
    
    init(viewModel: ContactDetailsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ContactDetailsView", bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    //MARK: - View Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = .None
        
        self.deleteBarButtonItem.rex_action <~ SignalProducer(value: CocoaAction(self.viewModel.deleteAction, input: ()))
        
        self.navigationItem.rightBarButtonItem = self.deleteBarButtonItem
        
        self.noContentView = TextOverlayView.attachContentUnavailableViewToView(self.view)
        self.noContentView.rex_hidden <~ self.viewModel.noContentViewHiddenProducer
        self.loadingView = LoadingView.attachToView(self.view, loadingViewModel: self.viewModel.loadingViewModel)

        self.viewModel.contactProducer.startWithNext { [weak self] contact in
            guard let sself = self, contact = contact else { return }
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
