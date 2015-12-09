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

class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var viewModel: ContactsViewModel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingOverlayView: UIView!
    
    //MARK: - Init
    
    init(dataController: LGDataController) {
        self.viewModel = ContactsViewModel(dataController: dataController)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        
        self.configureBindings()
    }
    
    //MARK: - Configuration
    
    func configureBindings() {
        self.loadingOverlayView.rac_hidden <~ self.viewModel.loadingProducer.map { !$0 }
        self.rac_title <~ self.viewModel.contactsCountProducer
        self.tableView.reloadWithProducer(self.viewModel.contacts.producer)
    }
    
    //MARK: - UITableViewDelegate, UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.contacts.value?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
        let contact = self.viewModel.contacts.value![indexPath.row]
        cell.textLabel?.text = contact.info
        return cell
    }
    
    //MARK: -

}
