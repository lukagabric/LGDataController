//
//  HomeViewModel.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation

public class HomeViewModel {
    
    private var navigationService: NavigationService
    
    //MARK: - Init

    init(dependencies: HomeModuleDependencies) {
        self.navigationService = dependencies.navigationService
    }
    
    //MARK: - User Interaction
    
    public func showContacts() {
        self.navigationService.pushContacts()
    }
    
    //MARK: -
    
}
