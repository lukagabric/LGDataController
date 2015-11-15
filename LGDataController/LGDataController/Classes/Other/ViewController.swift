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
        
        let context = NSManagedObjectContext()

        let tuple: ([AnotherManagedObject], NSError?) = AnotherManagedObject.lg_existingObjectsOrStubs(guids: [""], guidKey: "", context: context)
        
        let x = tuple.0

        print(x)
        
        let objects: [SomeManagedObject] = SomeManagedObject.lg_existingObjectsOrStubs(guids: [""], guidKey: "", context: context)
        
        print(objects)
        
        let firstObject = objects[0]
        
        print(firstObject)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

