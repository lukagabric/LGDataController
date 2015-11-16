//
//  LGUpdateInfo.swift
//  LGDataController
//
//  Created by Luka Gabric on 16/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation

struct LGUpdateInfo {
    
    var requestId: String
    var eTag: String
    var lastModified: String
    var updateDate: NSDate
    
    init(requestId: String, eTag: String, lastModified: String, updateDate: NSDate) {
        self.requestId = requestId
        self.eTag = eTag
        self.lastModified = lastModified
        self.updateDate = updateDate
    }
    
}
