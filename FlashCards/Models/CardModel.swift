//
//  CardModel.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation

class Card: NSObject {
    var answer:     String!
    var created:    NSDate!
    var enabled:    Bool!
    var id:         Int!
    var question:   String!
    
    override init() {
        
    }
    
    init(answer: String, question: String) {
        self.answer     = answer
        self.created    = NSDate()
        self.enabled    = true
        self.id         = Cards.sharedInstance().newIndex()
        self.question   = question
    }
    
    convenience init(coder aDecoder: NSCoder) {
        self.init()
        self.answer     = aDecoder.decodeObjectForKey("answer") as! String
        self.created    = aDecoder.decodeObjectForKey("created") as! NSDate
        self.enabled    = aDecoder.decodeBoolForKey("enabled")
        self.id         = Int(aDecoder.decodeIntForKey("id"))
        self.question   = aDecoder.decodeObjectForKey("question") as! String
    }

    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(answer, forKey: "answer")
        aCoder.encodeObject(created, forKey: "created")
        aCoder.encodeBool(enabled, forKey: "enabled")
        aCoder.encodeInteger(id, forKey: "id")
        aCoder.encodeObject(question, forKey: "question")
    }
    
    func update(answer: String?, question: String?) {
        self.answer     = answer
        self.question   = question
    }
    
    func destroy() {
        Cards.sharedInstance().destroyCard(self)
    }
}


// MARK: Equatable for card
func == (lhs: Card, rhs: Card) -> Bool {
    return lhs.id == rhs.id
}