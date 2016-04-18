//
//  NavigationService.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import UIKit

public class NavigationService: HomeNavigationServiceType, ContactsNavigationServiceType {
    
    private let dependencies: Dependencies
    
    var navigationController: UINavigationController {
        return self.dependencies.navigationController
    }
    
    //MARK: - Init

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    //MARK: - Common
    
    public func popView(animated animated: Bool) {
        self.navigationController.popViewControllerAnimated(animated)
    }

    public func showHomeView() {
        let homeViewModel = HomeViewModel(dependencies: self.dependencies)
        let homeViewController = HomeViewController(viewModel: homeViewModel)
        self.navigationController.setViewControllers([homeViewController], animated: false)
    }
    
    //MARK: - HomeNavigationServiceType
    
    public func pushContactsView() {
        let contactsViewModel = ContactsViewModel(dependencies: self.dependencies)
        let contactsViewController = ContactsViewController(viewModel: contactsViewModel)
        self.navigationController.pushViewController(contactsViewController, animated: true)
    }
    
    //MARK: - ContactsNavigationServiceType
    
    public func pushContactDetails(contactId contactId: String) {
        let contactDetailsViewModel = ContactDetailsViewModel(dependencies: self.dependencies, contactId: contactId)
        let contactDetailsViewController = ContactDetailsViewController(viewModel: contactDetailsViewModel)
        self.navigationController.pushViewController(contactDetailsViewController, animated: true)
    }
    
    //MARK: -
    
}
