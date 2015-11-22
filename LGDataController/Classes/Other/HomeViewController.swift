//
//  HomeViewController.swift
//  LGDataController
//
//  Created by Luka Gabric on 22/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit

public class HomeViewController: UIViewController {

    @IBAction func showContacts() {
        self.navigationController?.pushViewController(ContactsViewController(), animated: true)
    }

}
