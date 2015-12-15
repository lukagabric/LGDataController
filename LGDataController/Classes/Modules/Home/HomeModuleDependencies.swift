//
//  HomeModuleDependencies.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation

public protocol HomeModuleDependencies {
    
    var homeNavigationService: HomeNavigationServiceType { get }
    
}

public protocol HomeNavigationServiceType {
    
    func pushContactsView()
    
}
