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
    
    //MARK: - Init

    init(dependencies: Dependencies, navigationController: UINavigationController) {
        self.dependencies = dependencies
        self.navigationController = navigationController
    }
    
    //MARK: - Navigation

    public func showHome() {
        let homeViewModel = HomeViewModel(dependencies: dependencies)
        let homeViewController = HomeViewController(viewModel: homeViewModel)
        self.navigationController.setViewControllers([homeViewController], animated: false)
    }
    
    public func pushContacts() {
        let contactsViewModel = ContactsViewModel(dependencies: self.dependencies)
        let contactsViewController = ContactsViewController(viewModel: contactsViewModel)
        self.navigationController.pushViewController(contactsViewController, animated: true)
    }
    
    //MARK: -
    
}
