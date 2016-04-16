//
//  AppDelegate.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit
import CoreData
import enum Result.NoError

public typealias NoError = Result.NoError

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var dependencies: Dependencies!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.dependencies = Dependencies()
        
        return true
    }

}
