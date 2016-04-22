//
//  Contact.swift
//  LGDataController
//
//  Created by Luka Gabric on 15/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import CoreData
import ReactiveCocoa

public class Contact: ContentEntity {
    
    //MARK: - Entity Name
    
    override class func lg_entityName() -> String {
        return "Contact"
    }
    
    //MARK: - Mappings
    
    override class func lg_payloadToEntityMappings() -> [String : String] {
        return ["objectId" : "guid"]
    }
    
    //MARK: Info
    
    var info: String {
        var nameComponents: [String] = [String]()
        if let lastName = self.lastName { nameComponents.append(lastName) }
        if let firstName = self.firstName { nameComponents.append(firstName) }
        var info = nameComponents.joinWithSeparator(", ")
        if let email = self.email { info.appendContentsOf(" (\(email))") }
        return info
    }
    
    //MARK: Producers
    
    lazy var firstNameProducer: SignalProducer<String, NoError> = {
        let firstNameProperty = DynamicProperty(object: self, keyPath: "firstName")
        let firstNameProducer = firstNameProperty.producer.map { $0 as? String ?? "" }
        return firstNameProducer.takeUntil(self.deleteProducer)
    }()
    
    lazy var lastNameProducer: SignalProducer<String, NoError> = {
        let lastNameProperty = DynamicProperty(object: self, keyPath: "lastName")
        let lastNameProducer = lastNameProperty.producer.map { $0 as? String ?? "" }
        return lastNameProducer.takeUntil(self.deleteProducer)
    }()
    
    lazy var companyProducer: SignalProducer<String, NoError> = {
        let companyProperty = DynamicProperty(object: self, keyPath: "company")
        let companyProducer = companyProperty.producer.map { $0 as? String ?? "" }
        return companyProducer.takeUntil(self.deleteProducer)
    }()
    
    lazy var emailProducer: SignalProducer<String, NoError> = {
        let emailProperty = DynamicProperty(object: self, keyPath: "email")
        let emailProducer = emailProperty.producer.map { $0 as? String ?? "" }
        return emailProducer.takeUntil(self.deleteProducer)
    }()
    
    //MARK: Debug
    
    func debugLog() {
        print("Guid: \(self.guid)")
        print("First name: \(self.firstName)")
        print("Last name: \(self.lastName)")
        print("Company: \(self.company)")
        print("Last name: \(self.lastName)")
        print("Email: \(email)")
    }
    
    //MARK: -

}
