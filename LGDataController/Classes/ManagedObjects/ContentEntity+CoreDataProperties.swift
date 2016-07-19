//
//  ContentEntity+CoreDataProperties.swift
//  LGDataController
//
//  Created by Luka Gabric on 19/07/16.
//  Copyright © 2016 Luka Gabric. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ContentEntity {

    @NSManaged var createdAt: NSDate?
    @NSManaged var guid: String?
    @NSManaged var updatedAt: NSDate?
    @NSManaged var updatedAtString: String?
    @NSManaged var weight: NSNumber?
    @NSManaged var permanent: NSNumber?

}
