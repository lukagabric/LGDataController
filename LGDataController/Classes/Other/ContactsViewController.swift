//
//  ContactsViewController.swift
//  LGDataController
//
//  Created by Luka Gabric on 19/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit

class ContactsViewController: UIViewController {
    
    var viewModel: ContactsViewModel!
    
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
        
        self.viewModel.contactsCountProducer.startWithNext { [weak self] string in
            self?.title = string
        }
        
        self.viewModel.contactsProducer.startWithNext { contacts in
            guard let allContacts = contacts else { return }
            
            print(allContacts);
        }
    }

}
