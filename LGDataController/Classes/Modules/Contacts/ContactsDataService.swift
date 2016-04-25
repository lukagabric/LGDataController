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

public class ContactsDataService {
    
    //MARK: - Dependencies
    
    private let dataController: DataController
    
    //MARK: - Init
    
    init(dependencies: ContactsDependencies) {
        self.dataController = dependencies.dataController
    }
    
    //MARK: - Contacts Model Observer
    
    public func contactsModelObserver() -> ModelObserver<Contact> {
        let contactsFrc = self.contactsFrc()
        let contactsUpdateProducer = self.contactsUpdateProducer()
        
        return ModelObserver(fetchedResultsController: contactsFrc, updateProducer: contactsUpdateProducer?.lg_voidValue)
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
    
    public func contactsUpdateProducer() -> SignalProducer<[Contact]?, NSError>? {
        let parameters = self.parametersForLightContactsData()
        
        let contactsUpdateProducer = self.dataController.updateData(
            url: "https://api.parse.com/1/classes/contacts",
            methodName: "GET",
            parameters: parameters,
            requestId: "GetAllContacts",
            staleInterval: 10) { payload, response, context -> [Contact]? in
                guard let
                    dataDictionary = payload as? [String : AnyObject],
                    payloadArray = dataDictionary["results"] as? [[String : AnyObject]]
                    else { return nil }
                
                return Contact.parseAllContactsPayload(payloadArray, weight: .Light, context: context)
        }
        
        return contactsUpdateProducer
    }
    
    //MARK: - Contact
    
    public func contactModelObserver(contactId contactId: String, weight: ContentWeight = .Full) -> ModelObserver<Contact> {
        let contactFrc = self.contactFrc(contactId: contactId, weight: weight)
        let contactUpdateProducer = self.contactUpdateProducer(contactId: contactId, weight: weight)
        
        return ModelObserver(fetchedResultsController: contactFrc, updateProducer: contactUpdateProducer?.lg_voidValue)
    }
    
    private func contactFrc(contactId contactId: String, weight: ContentWeight = .Full) -> NSFetchedResultsController {
        let predicate = NSPredicate(format: "guid == %@ && weight >= %d", contactId, weight.rawValue)
        let sortDescriptor = NSSortDescriptor(key: "guid", ascending: true)
        
        let contactFetchRequest = NSFetchRequest(entityName: Contact.lg_entityName())
        contactFetchRequest.sortDescriptors = [sortDescriptor]
        contactFetchRequest.predicate = predicate
        
        let contactsFrc = NSFetchedResultsController(
            fetchRequest: contactFetchRequest,
            managedObjectContext: self.dataController.mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return contactsFrc;
    }
    
    public func contactUpdateProducer(contactId contactId: String, weight: ContentWeight = .Full) -> SignalProducer<Contact?, NSError>? {
        let parameters = self.parametersForObjectId(contactId)
        
        let contactUpdateProducer = self.dataController.updateData(
            url: "https://api.parse.com/1/classes/contacts",
            methodName: "GET",
            parameters: parameters,
            requestId: contactId,
            staleInterval: 10) { payload, response, context -> Contact? in
                guard let
                    dataDictionary = payload as? [String : AnyObject],
                    payloadArray = dataDictionary["results"] as? [[String : AnyObject]],
                    payload = payloadArray.first
                    else { return nil }
                
                return Contact.parseContactPayload(payload, weight: weight, context: context)
        }
        
        return contactUpdateProducer
    }
    
    //MARK: - Delete
    
    public func deleteContact(contact: Contact) {
        self.dataController.deleteObject(contact)
    }
    
    //MARK: - Convenience
    
    private func parametersForLightContactsData() -> [String : String] {
        let parameterValue = "firstName,lastName"
        let escapedParameterValue = parameterValue.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        return ["keys" : escapedParameterValue]
    }
    
    private func parametersForObjectId(objectId: String) -> [String : String] {
        let params = ["objectId" : objectId]
        let parameterValue = self.stringFromDict(params)
        let escapedParameterValue = parameterValue.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        return ["where" : escapedParameterValue]
    }
    
    private func stringFromDict(dict: [String : String]) -> String {
        let jsonData = try! NSJSONSerialization.dataWithJSONObject(dict, options: [])
        let jsonText = String(data: jsonData, encoding: NSASCIIStringEncoding)
        return jsonText!
    }
    
    //MARK: -
    
}
