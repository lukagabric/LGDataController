//
//  Contact+CoreDataProperties.swift
//  LGDataController
//
//  Created by Luka Gabric on 20/04/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Contact {

    @NSManaged var company: String?
    @NSManaged var email: String?
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?

}
