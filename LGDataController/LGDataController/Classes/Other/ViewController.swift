//
//  ViewController.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit
import CoreData

class SomeManagedObject: NSManagedObject {
    
}

class AnotherManagedObject: NSManagedObject {
    
}

class ViewController: UIViewController {
    
    var context: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

