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
    private let parametersError = NSError(domain: "Parameters error", code: 0, userInfo: nil)
    
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
                let payloadArray = dataDictionary["results"] as? [[String : AnyObject]] ?? [[String : AnyObject]]()
                let contacts: [Contact] = NSManagedObject.lg_mergeAndTruncateObjects(
                    payload: payloadArray,
                    payloadGuidKey: "objectId",
                    objectGuidKey: "guid",
                    weight: .Light,
                    context: context)
                return contacts
        }

        return contactsUpdateProducer
    }
    
    //MARK: - Contact
    
    public func contactWithId(contactId: String, weight: LGContentWeight = .Full) -> Contact? {
        let fetchRequest = NSFetchRequest(entityName: Contact.lg_entityName())
        let predicate = NSPredicate(format: "guid == %@ && weight >= %ld", contactId, weight.rawValue)
        fetchRequest.predicate = predicate
        
        let contact = try! self.dataController.mainContext.executeFetchRequest(fetchRequest).first as? Contact
        
        return contact
    }

    public func producerForContactWithId(contactId: String, weight: LGContentWeight = .Full) -> SignalProducer<Contact?, NSError> {
        guard let parameters = self.parametersForObjectId(contactId) else { return SignalProducer(error: self.parametersError) }
        
        let contact = self.contactWithId(contactId, weight: weight)

        let contactUpdateProducer = self.dataController.updateData(
            url: "https://api.parse.com/1/classes/contacts",
            methodName: "GET",
            parameters: parameters,
            requestId: contactId,
            staleInterval: 10) { (payload, response, context) -> Contact? in
                let dataDictionary = payload as! NSDictionary
                let payloadArray = dataDictionary["results"] as? [[String : AnyObject]] ?? [[String : AnyObject]]()
                let contacts: [Contact] = NSManagedObject.lg_mergeObjects(
                    payload: payloadArray,
                    payloadGuidKey: "objectId",
                    objectGuidKey: "guid",
                    weight: weight,
                    context: context)
                let contact = contacts.first
                return contact
        }
        
        let updateProducer = contactUpdateProducer ?? SignalProducer(value: nil)
        let resultProducer = contact != nil ? SignalProducer(value: contact) : updateProducer
        
        return resultProducer
    }

    //MARK: - Delete
    
    public func deleteContact(contact: Contact) {
        self.dataController.deleteObject(contact)
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
