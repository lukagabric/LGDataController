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

public class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var viewModel: ContactsViewModelType!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var loadingOverlayView: UIView!
    
    //MARK: - Init
    
    init(viewModel: ContactsViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - View Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        
        self.configureBindings()
    }
    
    //MARK: - Configuration
    
    func configureBindings() {
        self.loadingOverlayView.rac_hidden <~ self.viewModel.loadingProducer.map { !$0 }
        self.rac_title <~ self.viewModel.contactsTitleProducer
        self.tableView.reloadWithProducer(self.viewModel.contacts.producer)
    }
    
    //MARK: - UITableViewDelegate, UITableViewDataSource
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.contacts.value?.count ?? 0
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
        let contact = self.viewModel.contacts.value![indexPath.row]
        cell.textLabel?.text = contact.info
        return cell
    }
    
    //MARK: -

}
