//
//  ContactsDataService.swift
//  LGDataController
//
//  Created by Luka Gabric on 22/11/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa
import CoreData

public class ContactsDataService: ContactsDataServiceType {
    
    private let dataController: DataController
    
    //MARK: - Init
    
    init(dataController: DataController) {
        self.dataController = dataController
    }
    
    //MARK: - Contacts Model Observer
    
    public func contactsModelObserver() -> LGModelObserver<Contact> {
        let contactsFrc = self.contactsFrc()
        let updateProducer = self.contactsUpdateProducer()
        
        return LGModelObserver(fetchedResultsController: contactsFrc, updateProducer: updateProducer)
    }
    
    private func contactsFrc() -> NSFetchedResultsController {
        let contactsFetchRequest = NSFetchRequest(entityName: Contact.lg_entityName())
        let sortDescriptor = NSSortDescriptor(key: "lastName", ascending: true)
        contactsFetchRequest.sortDescriptors = [sortDescriptor]
        
        let contactsFrc = NSFetchedResultsController(
            fetchRequest: contactsFetchRequest,
            managedObjectContext: self.dataController.mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return contactsFrc;
    }
    
    private func contactsUpdateProducer() -> SignalProducer<[Contact]?, NSError>? {
        guard let parameters = self.parametersForLightContactsData() else { return nil }

        let contactsUpdateProducer = self.dataController.updateData(
            url: "https://api.parse.com/1/classes/contacts",
            methodName: "GET",
            parameters: parameters,
            requestId: "GetAllContacts",
            staleInterval: 10) { (payload, response, context) -> [Contact]? in
                let dataDictionary = payload as! NSDictionary
                let payloadArray = (dataDictionary["results"]) as! [[String : AnyObject]]
                let contacts: [Contact] = NSManagedObject.lg_mergeAndTruncateObjectsWithPayload(payloadArray, payloadGuidKey: "objectId", objectGuidKey: "guid", weight: .Light, context: context)
                return contacts
        }

        return contactsUpdateProducer
    }
    
    //MARK: - Contact
    
    public func contactWithId(contactId: String) -> Contact? {
        let fetchRequest = NSFetchRequest(entityName: Contact.lg_entityName())
        let predicate = NSPredicate(format: "guid == %@", contactId)
        fetchRequest.predicate = predicate
        
        let contact = try! self.dataController.mainContext.executeFetchRequest(fetchRequest).first as? Contact
        
        return contact
    }

    public func updateProducerForContactWithId(contactId: String) -> SignalProducer<Contact?, NSError>? {
        guard let parameters = self.parametersForObjectId(contactId) else { return nil }

        let contactUpdateProducer = self.dataController.updateData(
            url: "https://api.parse.com/1/classes/contacts",
            methodName: "GET",
            parameters: parameters,
            requestId: contactId,
            staleInterval: 10) { (payload, response, context) -> Contact? in
                let dataDictionary = payload as! NSDictionary
                let payloadArray = (dataDictionary["results"]) as! [[String : AnyObject]]
                let contacts: [Contact] = NSManagedObject.lg_mergeObjectsWithPayload(payloadArray, payloadGuidKey: "objectId", objectGuidKey: "guid", weight: .Full, context: context)
                let contact = contacts.first
                return contact
        }
        
        return contactUpdateProducer
    }
    
    public func mutablePropertyForContactWithId(contactId: String) -> MutableProperty<Contact?> {
        let contact = self.contactWithId(contactId)
        let contactMutableProperty = MutableProperty<Contact?>(contact)
        
        let contactUpdateProducer = self.updateProducerForContactWithId(contactId)
        
        if contact != nil {
            return contactMutableProperty
        }

        let updateProducer = contactUpdateProducer ?? SignalProducer<Contact?, NSError>.empty
        let updateNoErrorProducer = updateProducer.flatMapError { _ in SignalProducer<Contact?, NoError>.empty }

        contactMutableProperty <~ updateNoErrorProducer
        
        return contactMutableProperty
    }
    
    //MARK: - Private
    
    private func parametersForLightContactsData() -> [String : String]? {
        let parameterValue = "firstName,lastName"
        guard let escapedParameterValue = parameterValue.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()) else { return nil }
        
        return ["keys" : escapedParameterValue]
    }
    
    private func parametersForObjectId(objectId: String) -> [String : String]? {
        let params = ["objectId" : objectId]

        let parameterValue = self.stringFromDict(params)
        guard let escapedParameterValue = parameterValue.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()) else { return nil }
        
        return ["where" : escapedParameterValue]
    }
    
    private func stringFromDict(dict: [String : String]) -> String {
        let jsonData = try! NSJSONSerialization.dataWithJSONObject(dict, options: [])
        let jsonText = String(data: jsonData, encoding: NSASCIIStringEncoding)
        return jsonText!
    }
    
    //MARK: -
    
}
