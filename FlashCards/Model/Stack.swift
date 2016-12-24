//
//  Stack.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/23/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit

struct Stack {
    var name: String
    
    // Later assigned vars
    var record: CKRecord
    var cards = [NewCard]()
}

// MARK:- CloudKitCodable
extension Stack: CloudKitCodable {
    
    init?(record: CKRecord) throws {
        let decoder = CloudKitDecoder(record: record)
        self.record = record
        self.name = try decoder.decode("name")
    }
}

extension Stack {
    
    init() {
        self.name = ""
        self.record = CKRecord(recordType: .stack)
    }
    
    static var new: Stack {
        return Stack()
    }
    
    var newCard: NewCard {
        let stackReference = CKReference(record: record, action: .deleteSelf)
        let newCard = NewCard()
        newCard.record.setObject(stackReference, forKey: RecordType.Card.stack.rawValue)
        return newCard
    }
    
    @discardableResult
    mutating func save() -> Promise<Bool> {
        let promise = Promise<Bool>()
        
        record.setValuesForKeys(
            [
                RecordType.Stack.name.rawValue: name
            ]
        )
        
        CloudKitController.current.privateDB.save(record) { record, error in
            
            if let error = error {
                promise.reject(error)
            }
            
            if let record = record {
                DispatchQueue.main.sync {
                    self.record = record
                    promise.fulfill(true)
                }
            } else {
                promise.fulfill(false)
            }
        }
        
        return promise
    }
    
    func delete() -> Promise<Void> {
        let promise = Promise<Void>()
        
        CloudKitController.current.privateDB.delete(withRecordID: record.recordID) { recordId, error in
            if let error = error {
                promise.reject(error)
            }
            
            if let _ = recordId {
                promise.fulfill()
            }
        }
        
        return promise
    }
    
    func fetchCards() -> Promise<[NewCard]> {
        return CloudKitController.current.getCardsFromStack(record: record)
    }
}

struct NewCard {
    var topic: String
    var details: String
    
    // Later assigned vars
    var record: CKRecord
}

// MARK:- CloudKitCodable
extension NewCard: CloudKitCodable {
    
    init(record: CKRecord) throws {
        let decoder = CloudKitDecoder(record: record)
        do {
            self.record = record
            self.topic = try decoder.decode("topic")
            self.details = try decoder.decode("details")
        } catch {
            throw error
        }
    }
}

extension NewCard {
    
    init() {
        self.topic = ""
        self.details = ""
        self.record = CKRecord(recordType: .card)
    }
    
    static var new: NewCard {
        return NewCard()
    }
    
    @discardableResult
    mutating func save() -> Promise<Bool> {
        let promise = Promise<Bool>()
        
        record.setValuesForKeys(
            [
                RecordType.Card.topic.rawValue: topic,
                RecordType.Card.details.rawValue: details
            ]
        )
        
        CloudKitController.current.privateDB.save(record) { record, error in
            
            if let error = error {
                promise.reject(error)
            }
            
            if let record = record {
                DispatchQueue.main.sync {
                    self.record = record
                    promise.fulfill(true)
                }
            } else {
                promise.fulfill(false)
            }
        }
        
        return promise
    }
    
    func delete() -> Promise<Void> {
        let promise = Promise<Void>()
        
        CloudKitController.current.privateDB.delete(withRecordID: record.recordID) { recordId, error in
            if let error = error {
                promise.reject(error)
            }
            
            if let _ = recordId {
                promise.fulfill()
            }
        }
        
        return promise
    }
}
