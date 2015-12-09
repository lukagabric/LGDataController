//
//  ContactsViewController.swift
//  LGDataController
//
//  Created by Luka Gabric on 19/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit
import ReactiveCocoa
import CoreData

class ContactsViewController: UIViewController {
    
    var viewModel: ContactsViewModel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingOverlayView: UIView!
    
    init(dataController: LGDataController) {
        self.viewModel = ContactsViewModel(dataController: dataController)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureBindings()
    }
    
    func configureBindings() {
        self.viewModel.loadingProducer.startWithNext { loading in
            print("Contacts \(loading ? "ARE" : "ARE NOT") loading!")
        }
        
        self.loadingOverlayView.rac_hidden <~ self.viewModel.loadingProducer.map { !$0 }
        
        self.viewModel.contactsCountProducer.startWithNext { [weak self] string in
            self?.title = string
        }
        
        self.viewModel.contactsProducer.startWithNext { contacts in
            guard let allContacts = contacts else { return }
            
            print(allContacts);
        }
    }

}
