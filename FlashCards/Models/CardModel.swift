//
//  CardModel.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation

class Card: NSObject {
    var created:    NSDate!
    var details:    String!
    var hidden:     Bool!
    var id:         Int!
    var order:      Int!
    var topic:      String!
    
    override init() {
        
    }
    
    init(topic: String, details: String) {
        self.created    = NSDate()
        self.hidden     = false
        self.details    = details
        self.id         = Cards.sharedInstance().newIndex()
        self.order      = Cards.sharedInstance().cards.count + 1
        self.topic      = topic
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        self.init()
        self.created    = aDecoder.decodeObjectForKey("created") as! NSDate
        self.details    = aDecoder.decodeObjectForKey("question") as! String
        self.hidden     = aDecoder.decodeBoolForKey("enabled")
        self.id         = Int(aDecoder.decodeIntForKey("id"))
        self.order      = Int(aDecoder.decodeIntForKey("order"))
        self.topic      = aDecoder.decodeObjectForKey("answer") as! String
    }

    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(created, forKey: "created")
        aCoder.encodeObject(details, forKey: "question")
        aCoder.encodeBool(hidden, forKey: "enabled")
        aCoder.encodeInteger(id, forKey: "id")
        aCoder.encodeInteger(order, forKey: "order")
        aCoder.encodeObject(topic, forKey: "answer")
    }
    
    func update(topic: String?, details: String?, order: Int?) {
        self.details    = details
        self.topic      = topic
        self.order      = order
    }
    
    func destroy() {
        Cards.sharedInstance().destroyCard(self)
    }
    
    func hideCard() {
        self.hidden = true
    }
}


// MARK: Equatable for card
func == (lhs: Card, rhs: Card) -> Bool {
    return lhs.id == rhs.id
}