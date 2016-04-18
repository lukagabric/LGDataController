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
    var navigationController: UINavigationController!
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.navigationController = UINavigationController()
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = self.navigationController
        self.window?.makeKeyAndVisible()

        self.dependencies = Dependencies(navigationController: self.navigationController)
        
        self.dependencies.navigationService.showHomeView()
        
        return true
    }

}
