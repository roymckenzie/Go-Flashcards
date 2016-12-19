//
//  Card.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/17/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation

open class Card: NSObject, NSCoding {
    open unowned let subject: Subject
    open var created:    Date
    open var details:    String
    open var hidden:     Bool
    open var id:         Int
    open var order:      Int
    open var topic:      String
    
    public init(subject: Subject, topic: String, details: String) {
        self.subject    = subject
        self.created    = Date()
        self.hidden     = false
        self.details    = details
        self.id         = self.subject.newIndex()
        self.order      = self.subject.cards.count + 1
        self.topic      = topic
    }
    
    required convenience public init(coder aDecoder: NSCoder) {
        
        NSKeyedUnarchiver.setClass(Card.self, forClassName: "Card")
        NSKeyedUnarchiver.setClass(Subject.self, forClassName: "Subject")
        
        
        // MARK: 0.2 migration: Migrate from old model in 0.1 -- ADDED SUBJECT
        let _subject: Subject
        if let __subject = aDecoder.decodeObject(forKey: "subject") as? Subject {
            _subject = __subject
        }else{
            _subject = DataManager.current.subjects.first!
        }
        
        // MARK: 0.2 migration: Migrate from old model in 0.1 -- CHANGED "answer" to "topic"
        let _topic: String
        if let __topic = aDecoder.decodeObject(forKey: "topic") as? String {
            _topic = __topic
        }else{
            _topic = aDecoder.decodeObject(forKey: "answer") as! String
        }
        
        // MARK: 0.2 migration: Migrate from old model in 0.1 -- CHANGED "question" to "details"
        let _details: String
        if let __details = aDecoder.decodeObject(forKey: "details") as? String {
            _details = __details
        }else{
            _details = aDecoder.decodeObject(forKey: "question") as! String
        }
        
        self.init(subject: _subject, topic: _topic, details: _details)
        self.created    = aDecoder.decodeObject(forKey: "created") as! Date
        self.hidden     = aDecoder.decodeBool(forKey: "hidden")
        self.id         = aDecoder.decodeInteger(forKey: "id")
        self.order      = aDecoder.decodeInteger(forKey: "order")
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(subject, forKey: "subject")
        aCoder.encode(created, forKey: "created")
        aCoder.encode(details, forKey: "details")
        aCoder.encode(hidden, forKey: "hidden")
        aCoder.encode(id, forKey: "id")
        aCoder.encode(order, forKey: "order")
        aCoder.encode(topic, forKey: "topic")
    }
    
    open func update(_ topic: String, details: String, order: Int) {
        self.details    = details
        self.topic      = topic
        self.order      = order
    }
    
    open func destroy() {
        subject.destroyCard(self)
    }
    
    open func hideCard() {
        self.hidden = true
    }
    
    open func unHideCard() {
        self.hidden = false
    }
}

// MARK: Equatable for card
public func == (lhs: Card, rhs: Card) -> Bool {
    return lhs.id == rhs.id
}

import CloudKit

struct NewCard {
    let topic: String
    let details: String
}

// MARK:- CloudKitCodable
extension NewCard: CloudKitCodable {

    init(record: CKRecord) throws {
        let decoder = CloudKitDecoder(record: record)
        do {
            self.topic = try decoder.decode("topic")
            self.details = try decoder.decode("details")
        } catch {
            throw error
        }
    }
}
