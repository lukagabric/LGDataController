//
//  HomeViewModel.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation

public class HomeViewModel: HomeViewModelType {
    
    private var navigationService: HomeNavigationServiceType
    
    //MARK: - Init

    init(dependencies: HomeDependencies) {
        self.navigationService = dependencies.homeNavigationService
    }
    
    //MARK: - User Interaction
    
    public func showContacts() {
        self.navigationService.pushContactsView()
    }
    
    //MARK: -
    
}
