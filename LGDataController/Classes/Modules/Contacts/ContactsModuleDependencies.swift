//
//  ContactsModuleDependencies.swift
//  LGDataController
//
//  Created by Luka Gabric on 10/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation

protocol ContactsModuleDependencies {
    
    var dataController: LGDataController { get }
    var navigationService: NavigationService { get }
    
}
