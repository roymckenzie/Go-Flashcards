//
//  SubjectModel.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/3/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation

open class Subject: NSObject, NSCoding {
    open var cards   = [Card]()
    open var id:     Int!
    open var name:   String!

    public init(name: String, id: Int) {
        self.name   = name
        self.id     = id
    }
    
    public init(name: String) {
        self.name = name
        self.id = User.sharedInstance().newIndex()
    }

    open func encode(with aCoder: NSCoder) {
        aCoder.encode(cards, forKey: "cards")
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
    }
    
    required public init(coder aDecoder: NSCoder) {
        NSKeyedUnarchiver.setClass(Card.self, forClassName: "Card")
        self.cards = aDecoder.decodeObject(forKey: "cards") as! [Card]
        self.id = aDecoder.decodeInteger(forKey: "id")
        self.name = aDecoder.decodeObject(forKey: "name") as! String
    }
    
    
    open func addCard(_ card: Card) {
        cards.append(card)
        User.sharedInstance().saveSubjects()
    }
    
    open func updateCard(_ card: Card) {
        cards.enumerated().forEach { index, _card in
            if _card == card {
                _card.topic = card.topic
                _card.details = card.details
            }
        }
        User.sharedInstance().saveSubjects()
    }
    
    open func destroyCard(_ card: Card) {
        cards.enumerated().forEach { index, _card in
            if _card == card {
                cards.remove(at: index)
            }
        }
        User.sharedInstance().saveSubjects()
    }
    
    open func visibleCards() -> [Card] {
        cards.sorted { (cardOne, cardTwo) -> Bool in
            return cardOne.order < cardTwo.order
        }
        return cards.filter { (_card) -> Bool in
            return !_card.hidden!
        }
    }
    
    open func hiddenCards() -> [Card] {
        cards.sorted { (cardOne, cardTwo) -> Bool in
            return cardOne.order < cardTwo.order
        }
        return cards.filter { (_card) -> Bool in
            return _card.hidden!
        }
    }
    
    open func getRandomCard(_ excludeCard: Card?) -> Card? {
        var _cards = visibleCards()
        if let excludeCard = excludeCard {
            for (index, _card) in enumerate(_cards) {
                if _card == excludeCard {
                    _cards.remove(at: index)
                }
            }
        }
        if _cards.isEmpty {
            return nil
        }
        let cardCount = _cards.count
        let randomNumber = Int(arc4random_uniform(UInt32(cardCount)))
        return _cards[randomNumber]
    }
    
    open func hideCard(_ card: Card) {
        cards.filter { (_card) -> Bool in
            card == _card
        }.first?.hideCard()
        User.sharedInstance().saveSubjects()
    }
    
    open func unHideCard(_ card: Card) {
        cards.filter { (_card) -> Bool in
            card == _card
        }.first?.unHideCard()
        User.sharedInstance().saveSubjects()
    }

    
    open func newIndex() -> Int {
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
