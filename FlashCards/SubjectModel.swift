//
//  SubjectModel.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/3/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation

public class Subject: NSObject, NSCoding {
    public var cards   = [Card]()
    public var id:     Int!
    public var name:   String!

    public init(name: String, id: Int) {
        self.name   = name
        self.id     = id
    }
    
    public init(name: String) {
        self.name = name
        self.id = User.sharedInstance().newIndex()
    }

    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(cards, forKey: "cards")
        aCoder.encodeInteger(id, forKey: "id")
        aCoder.encodeObject(name, forKey: "name")
    }
    
    required public init(coder aDecoder: NSCoder) {
        NSKeyedUnarchiver.setClass(Card.self, forClassName: "Card")
        self.cards = aDecoder.decodeObjectForKey("cards") as! [Card]
        self.id = aDecoder.decodeIntegerForKey("id")
        self.name = aDecoder.decodeObjectForKey("name") as! String
    }
    
    
    public func addCard(card: Card) {
        cards.append(card)
        User.sharedInstance().saveSubjects()
    }
    
    public func updateCard(card: Card) {
        for (index, _card) in enumerate(cards) {
            if _card == card {
                _card.topic = card.topic
                _card.details = card.details
            }
        }
        User.sharedInstance().saveSubjects()
    }
    
    public func destroyCard(card: Card) {
        for (index, _card) in enumerate(cards) {
            if _card == card {
                cards.removeAtIndex(index)
            }
        }
        User.sharedInstance().saveSubjects()
    }
    
    public func visibleCards() -> [Card] {
        cards.sort { (cardOne, cardTwo) -> Bool in
            return cardOne.order < cardTwo.order
        }
        return cards.filter { (_card) -> Bool in
            return !_card.hidden!
        }
    }
    
    public func hiddenCards() -> [Card] {
        cards.sort { (cardOne, cardTwo) -> Bool in
            return cardOne.order < cardTwo.order
        }
        return cards.filter { (_card) -> Bool in
            return _card.hidden!
        }
    }
    
    public func getRandomCard() -> Card? {
        if visibleCards().isEmpty {
            return nil
        }
        let cardCount = visibleCards().count
        let randomNumber = Int(arc4random_uniform(UInt32(cardCount)))
        return visibleCards()[randomNumber]
    }
    
    public func hideCard(card: Card) {
        for _card in cards {
            if _card == card {
                _card.hideCard()
            }
        }
        User.sharedInstance().saveSubjects()
    }
    
    public func unHideCard(card: Card) {
        for _card in cards {
            if _card == card {
                _card.unHideCard()
            }
        }
        User.sharedInstance().saveSubjects()
    }

    
    public func newIndex() -> Int {
        var newIndex = 0
        for card in cards {
            if card.id > newIndex {
                newIndex = card.id
            }
        }
        return newIndex + 1
    }

    
}

// MARK: Equatable for subject
public func == (lhs: Subject, rhs: Subject) -> Bool {
    return lhs.id == rhs.id
}