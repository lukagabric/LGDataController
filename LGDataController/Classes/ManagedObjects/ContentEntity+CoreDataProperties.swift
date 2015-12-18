//
//  ContentEntity+CoreDataProperties.swift
//  LGDataController
//
//  Created by Luka Gabric on 18/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ContentEntity {

    @NSManaged public var guid: String?
    @NSManaged public var weight: NSNumber?
    @NSManaged public var createdAt: NSDate?
    @NSManaged public var updatedAt: NSDate?
    @NSManaged public var updatedAtString: String?
    @NSManaged public var permanentEntity: PermanentEntity?
    @NSManaged public var sessionEntity: SessionEntity?

}
