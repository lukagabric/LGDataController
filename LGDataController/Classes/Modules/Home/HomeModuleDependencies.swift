//
//  HomeModuleDependencies.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation

public protocol HomeModuleDependencies {
    
    var homeNavigationService: HomeNavigationService { get }
    
}

public protocol HomeNavigationService {
    
    func pushContacts()
    
}

public protocol HomeViewModelType {
    
    func showContacts()
    
}
