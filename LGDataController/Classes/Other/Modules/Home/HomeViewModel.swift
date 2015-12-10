//
//  HomeViewModel.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation

class HomeViewModel {
    
    var navigationService: NavigationService
    
    //MARK: - Init

    init(dependencies: HomeModuleDependencies) {
        self.navigationService = dependencies.navigationService
    }
    
    //MARK: - User Interaction
    
    func showContacts() {
        self.navigationService.pushContacts()
    }
    
    //MARK: -
    
}
