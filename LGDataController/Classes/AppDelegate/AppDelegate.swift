//
//  AppDelegate.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var dependencies: Dependencies!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.dependencies = Dependencies()
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.dependencies.navigationService.configureRootViewControllerForWindow(self.window!)
        self.window?.makeKeyAndVisible()
        
        return true
    }

}
