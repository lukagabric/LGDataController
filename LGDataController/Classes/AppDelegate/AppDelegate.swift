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
        let navigationController = UINavigationController()
        self.dependencies = Dependencies(navigationController: navigationController, application: application)
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
        self.dependencies.navigationService.showHomeView()
        
        return true
    }

}
