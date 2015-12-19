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

public protocol ContactsViewModelType {
    
    var contacts: MutableProperty<[Contact]?> { get }
    var loadingHidden: MutableProperty<Bool> { get }
    var contactsTitleProducer: SignalProducer<String, NoError> { get }

    func didSelectContact(contact: Contact)

}

public class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var viewModel: ContactsViewModelType!
    
    private var contacts: [Contact]? {
        return self.viewModel.contacts.value
    }
    
    @IBOutlet private weak var tableView: UITableView!
    
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

        LGLoadingView.attachToView(self.view).rac_hidden <~ self.viewModel.loadingHidden.producer

        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        
        self.configureBindings()
    }
    
    //MARK: - Configuration
    
    func configureBindings() {
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
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let contact = self.viewModel.contacts.value![indexPath.row]
        self.viewModel.didSelectContact(contact)
    }
    
    //MARK: -

}
