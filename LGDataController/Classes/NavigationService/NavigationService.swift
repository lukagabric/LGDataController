//
//  NavigationService.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import UIKit

public class NavigationService: HomeNavigationService {
    
    private let dependencies: Dependencies
    private var navigationController: UINavigationController
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        self.navigationController = UINavigationController()
    }
    
    public func configureRootViewControllerForWindow(window: UIWindow) {
        let homeViewController = HomeViewController(dependencies: self.dependencies)
        self.navigationController.setViewControllers([homeViewController], animated: false)
        window.rootViewController = self.navigationController
    }
    
    public func pushContacts() {
        let contactsViewController = ContactsViewController(dependencies: self.dependencies)
        self.navigationController.pushViewController(contactsViewController, animated: true)
    }
    
}
