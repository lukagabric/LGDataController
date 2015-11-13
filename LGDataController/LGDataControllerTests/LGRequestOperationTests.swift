//
//  LGRequestOperationTests.swift
//  LGDataController
//
//  Created by Luka Gabric on 13/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import XCTest
@testable import LGDataController

class LGRequestOperationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRequest() {
        let operationQueue = NSOperationQueue()
        operationQueue.suspended = true
        operationQueue.maxConcurrentOperationCount = 1

        guard let url = NSURL(string: "http://lukagabric.com/wp-content/contacts-api/contacts") else {
            XCTAssertTrue(false)
            return
        }
        
        let op1 = LGRequestOperation(session: NSURLSession.sharedSession(), request: NSURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 5))
        op1.signal.observeNext { data, response in
            let string = String(data: data, encoding: NSUTF8StringEncoding)
            print("\(string)\n==========================\n\(response)")
        }
        op1.signal.observeFailed { error in
            print("Error:\n\(error)")
        }
        
        operationQueue.addOperation(op1)
        
        operationQueue.suspended = false
        operationQueue.waitUntilAllOperationsAreFinished()
    }
        
}
