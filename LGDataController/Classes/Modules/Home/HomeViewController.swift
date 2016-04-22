//
//  HomeViewController.swift
//  LGDataController
//
//  Created by Luka Gabric on 22/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit

public protocol HomeViewModelType {
    
    func showContacts()
    
}

public class HomeViewController: UIViewController {

    var viewModel: HomeViewModelType
    
    //MARK: - Init
    
    init(viewModel: HomeViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: "HomeView", bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    //MARK: - User Interaction

    @IBAction private func showContacts() {
        self.viewModel.showContacts()
    }
    
    //MARK: -

}
