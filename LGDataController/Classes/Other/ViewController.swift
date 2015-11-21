//
//  ViewController.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit
import CoreData
import ReactiveCocoa

class ViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    var session: NSURLSession!
    var dataController: LGDataController!
    var signal: Signal<[Contact], NSError>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate else { return }
        self.dataController = LGDataController(session: session, mainContext: appDelegate.managedObjectContext)
        
        let contactsSignalOptional = self.dataController.updateData(
            url: "http://lukagabric.com/wp-content/contacts-api/contacts",
            methodName: "GET",
            parameters: nil,
            requestId: "ContactsJSON",
            staleInterval: 10) { (data, response, context) -> [Contact] in
                let contacts = Contact.parseFullContactsData(data as! NSArray, context: context)
                return contacts
        }
        
        guard let contactsSignal = contactsSignalOptional else { return }
        self.signal = contactsSignal
        
        self.signal.observeNext { contacts in
            print(contacts)
            for contact in contacts {
                contact.debugLog()
            }
            
            if let contact = contacts.first {
                print("\(contact.managedObjectContext! == self.dataController.mainContext ? "" : "NOT")using main context")
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

