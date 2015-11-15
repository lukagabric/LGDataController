//
//  LGDataUpdateInfo+CoreDataProperties.swift
//  LGDataController
//
//  Created by Luka Gabric on 15/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension LGDataUpdateInfo {

    @NSManaged var etag: String?
    @NSManaged var lastModified: String?
    @NSManaged var lastUpdateDate: NSDate?
    @NSManaged var requestId: String?

}
