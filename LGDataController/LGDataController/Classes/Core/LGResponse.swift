//
//  LGResponse.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation

public struct LGResponse {
    
    let httpResponse: NSHTTPURLResponse
    let responseData: NSData
    let etag: String?
    let lastModified: String?
    let statusCode: Int
    
    init(response: NSHTTPURLResponse, data: NSData) {
        self.httpResponse = response
        self.responseData = data
        self.statusCode = response.statusCode
        self.etag = self.httpResponse.allHeaderFields["Etag"] as? String
        self.lastModified = self.httpResponse.allHeaderFields["Last-Modified"] as? String
    }
    
}
