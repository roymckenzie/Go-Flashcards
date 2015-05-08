//
//  CardModel.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation

public class Card: NSObject, NSCoding {
    public unowned let subject: Subject
    public var created:    NSDate!
    public var details:    String!
    public var hidden:     Bool!
    public var id:         Int!
    public var order:      Int!
    public var topic:      String!
    
    public init(subject: Subject, topic: String, details: String) {
        self.subject    = subject
        self.created    = NSDate()
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
        if let __subject = aDecoder.decodeObjectForKey("subject") as? Subject {
            _subject = __subject
        }else{
            _subject = _user.subjects.first!
        }
        
        // MARK: 0.2 migration: Migrate from old model in 0.1 -- CHANGED "answer" to "topic"
        let _topic: String
        if let __topic = aDecoder.decodeObjectForKey("topic") as? String {
            _topic = __topic
        }else{
            _topic = aDecoder.decodeObjectForKey("answer") as! String
        }
        
        // MARK: 0.2 migration: Migrate from old model in 0.1 -- CHANGED "question" to "details"
        let _details: String
        if let __details = aDecoder.decodeObjectForKey("details") as? String {
            _details = __details
        }else{
            _details = aDecoder.decodeObjectForKey("question") as! String
        }
        
        self.init(subject: _subject, topic: _topic, details: _details)
        self.created    = aDecoder.decodeObjectForKey("created") as! NSDate
        self.hidden     = aDecoder.decodeBoolForKey("hidden")
        self.id         = aDecoder.decodeIntegerForKey("id")
        self.order      = aDecoder.decodeIntegerForKey("order")
    }

    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(subject, forKey: "subject")
        aCoder.encodeObject(created, forKey: "created")
        aCoder.encodeObject(details, forKey: "details")
        aCoder.encodeBool(hidden, forKey: "hidden")
        aCoder.encodeInteger(id, forKey: "id")
        aCoder.encodeInteger(order, forKey: "order")
        aCoder.encodeObject(topic, forKey: "topic")
    }
    
    public func update(topic: String?, details: String?, order: Int?) {
        self.details    = details
        self.topic      = topic
        self.order      = order
    }
    
    public func destroy() {
        subject.destroyCard(self)
    }
    
    public func hideCard() {
        self.hidden = true
    }
    
    public func unHideCard() {
        self.hidden = false
    }
}


// MARK: Equatable for card
public func == (lhs: Card, rhs: Card) -> Bool {
    return lhs.id == rhs.id
}