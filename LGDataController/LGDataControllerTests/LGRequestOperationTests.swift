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
        let expectation = expectationWithDescription("...")
        
        let operationQueue = NSOperationQueue()
        operationQueue.suspended = true
        operationQueue.maxConcurrentOperationCount = 1

        guard let url = NSURL(string: "http://lukagabric.com/wp-content/contacts-api/contacts") else {
            XCTAssertTrue(false)
            return
        }
        
        let op1 = LGRequestOperation(session: NSURLSession.sharedSession(), request: NSURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 5))
        
        op1.signal.observeNext { response in
            print(response)
            print("\(String(data: response.responseData, encoding: NSUTF8StringEncoding))")
        }
        op1.signal.observeFailed { error in
            print("Error:\n\(error)")
        }
        
        op1.signal.observe { event in
            switch event {
            case .Next(let response):
                print(response)
                print("\(String(data: response.responseData, encoding: NSUTF8StringEncoding))")
            case .Failed(let error):
                print("Error:\n\(error)")
                expectation.fulfill()
            case .Completed:
                expectation.fulfill()                
                break
            default: break
            }
        }
        
        operationQueue.addOperation(op1)
        
        operationQueue.suspended = false
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
        
}
