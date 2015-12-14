//
//  HomeViewModel.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation

public class HomeViewModel: HomeViewModelType {
    
    private var navigationService: HomeNavigationService
    
    //MARK: - Init

    init(dependencies: HomeModuleDependencies) {
        self.navigationService = dependencies.homeNavigationService
    }
    
    //MARK: - User Interaction
    
    public func showContacts() {
        self.navigationService.pushContacts()
    }
    
    //MARK: -
    
}
