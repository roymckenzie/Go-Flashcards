//
//  SubjectModel.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/3/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation

class Subject: NSObject, NSCoding {
    var cards   = [Card]()
    var id:     Int!
    var name:   String!

    init(name: String, id: Int) {
        self.name   = name
        self.id     = id
    }
    
    init(name: String) {
        self.name = name
        self.id = User.sharedInstance().newIndex()
    }

    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(cards, forKey: "cards")
        aCoder.encodeInteger(id, forKey: "id")
        aCoder.encodeObject(name, forKey: "name")
    }
    
    required init(coder aDecoder: NSCoder) {
        self.cards = aDecoder.decodeObjectForKey("cards") as! [Card]
        self.id = aDecoder.decodeIntegerForKey("id")
        self.name = aDecoder.decodeObjectForKey("name") as! String
    }
    
    
    func addCard(card: Card) {
        cards.append(card)
        User.sharedInstance().saveSubjects()
    }
    
    func updateCard(card: Card) {
        for (index, _card) in enumerate(cards) {
            if _card == card {
                cards.removeAtIndex(index)
                cards.append(card)
            }
        }
        User.sharedInstance().saveSubjects()
    }
    
    func destroyCard(card: Card) {
        for (index, _card) in enumerate(cards) {
            if _card == card {
                cards.removeAtIndex(index)
            }
        }
        User.sharedInstance().saveSubjects()
    }
    
    func visibleCards() -> [Card] {
        cards.sort { (cardOne, cardTwo) -> Bool in
            return cardOne.order < cardTwo.order
        }
        return cards.filter { (_card) -> Bool in
            return !_card.hidden!
        }
    }
    
    func hiddenCards() -> [Card] {
        cards.sort { (cardOne, cardTwo) -> Bool in
            return cardOne.order < cardTwo.order
        }
        return cards.filter { (_card) -> Bool in
            return _card.hidden!
        }
    }
    
    func getRandomCard() -> Card {
        let cardCount = visibleCards().count
        let randomNumber = Int(arc4random_uniform(UInt32(cardCount)))
        return visibleCards()[randomNumber]
    }
    
    func hideCard(cardId: Int) {
        for card in cards {
            if card.id == cardId {
                card.hideCard()
            }
        }
        User.sharedInstance().saveSubjects()
    }

    
    func newIndex() -> Int {
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
func == (lhs: Subject, rhs: Subject) -> Bool {
    return lhs.id == rhs.id
}