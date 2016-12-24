//
//  CloudKitController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/18/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit

enum RecordType: String {
    case card
    case stack
    
    enum Card: String {
        case topic
        case details
        case stack
    }
    
    enum Stack: String {
        case name
    }
}

extension RecordType: CustomStringConvertible {
    
    var description: String {
        return self.rawValue.capitalized
    }
}

/// CloudKit database access controller
struct CloudKitController {
    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase
    
    static let current: CloudKitController = CloudKitController()
    
    init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
}

extension CloudKitController {
    
    public func getStacks() -> Promise<[Stack]> {
        let promise = Promise<[Stack]>()
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: .stack, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { records, error in
            
            if let error = error {
                promise.reject(error)
            }
            
            if let records = records {
                do {
                    let stacks = try records.flatMap(Stack.init)
                    promise.fulfill(stacks)
                } catch {
                    promise.reject(error)
                }
            } else {
                promise.fulfill([])
            }
        }
        
        return promise
    }
    
    public func getCardsFromStack(record: CKRecord) -> Promise<[NewCard]> {
        let promise = Promise<[NewCard]>()
        
        let reference = CKReference(record: record, action: .none)
        let predicate = NSPredicate(format: "stack == %@", reference)
        let query = CKQuery(recordType: .card, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { records, error in
            
            if let error = error {
                promise.reject(error)
            }
            
            if let records = records {
                do {
                    let stacks = try records.flatMap(NewCard.init)
                    promise.fulfill(stacks)
                } catch {
                    promise.reject(error)
                }
            } else {
                promise.fulfill([])
            }
        }
        
        return promise
    }
}

// MARK:- CKQuery extension
extension CKQuery {
    
    /// Initialize a `CKQuery` with a `RecordType` enum value
    convenience init(recordType: RecordType, predicate: NSPredicate) {
        self.init(recordType: recordType.description, predicate: predicate)
    }
}

// MARK:- CKRecord extension
extension CKRecord {
    
    /// Initialize a `CKRecord` with a `RecordType` enum value
    convenience init(recordType: RecordType) {
        self.init(recordType: recordType.rawValue)
    }
    
    /// Initialize a `CKRecord` with a `RecordType` enum value and Record ID
    convenience init(recordType: RecordType, recordID: CKRecordID) {
        self.init(recordType: recordType.rawValue, recordID: recordID)
    }
}
