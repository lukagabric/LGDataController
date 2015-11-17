//
//  LGUpdateInfo.swift
//  LGDataController
//
//  Created by Luka Gabric on 16/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation

class LGUpdateInfo {
    
    var requestId: String
    var eTag: String?
    var lastModified: String?
    var updateDate: NSDate
    
    init(requestId: String) {
        self.requestId = requestId
        self.updateDate = NSDate.distantPast()
    }
    
}
