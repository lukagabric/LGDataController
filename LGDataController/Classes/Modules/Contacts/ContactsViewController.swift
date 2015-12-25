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
import Rex

public protocol ContactsViewModelType {

    var contacts: AnyProperty<[Contact]?> { get }
    var noContentViewHidden: AnyProperty<Bool> { get }
    var loadingViewModel: LoadingViewModelType! { get }
    var contactsTitle: AnyProperty<String> { get }

    func didSelectContact(contact: Contact)

}

public class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var viewModel: ContactsViewModelType!
    
    private var contacts: [Contact]? {
        return self.viewModel.contacts.value
    }
    
    @IBOutlet private weak var tableView: UITableView!
    weak var loadingView: LGLoadingView!
    weak var noContentView: LGTextOverlayView!

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

        self.noContentView = LGTextOverlayView.attachContentUnavailableViewToView(self.view)
        self.noContentView.rex_hidden <~ self.viewModel.noContentViewHidden
        self.loadingView = LGLoadingView.attachToView(self.view, loadingViewModel: self.viewModel.loadingViewModel)
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        
        self.configureBindings()
    }
    
    //MARK: - Configuration
    
    func configureBindings() {
        self.rac_title <~ self.viewModel.contactsTitle.producer
        self.tableView.rac_tableReload <~ self.viewModel.contacts.producer.lg_tableReloadProducer
    }
    
    //MARK: - UITableViewDelegate, UITableViewDataSource
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.contacts.value?.count ?? 0
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
        let contact = self.contacts![indexPath.row]
        cell.textLabel?.text = contact.info
        return cell
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let contact = self.contacts![indexPath.row]
        self.viewModel.didSelectContact(contact)
        
        if indexPath.row == 0 {
            self.simulateDeleteOfContact(contact)
        }
    }
    
    //MARK: - Just for testing when an object is deleted under you on e.g. details screen
    
    func simulateDeleteOfContact(contact: Contact) {
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            contact.managedObjectContext?.deleteObject(contact)
            try! contact.managedObjectContext?.save()
        }
    }

    //MARK: -

}
