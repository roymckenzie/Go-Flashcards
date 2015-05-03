//
//  CardsModel.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation

let _cards = Cards()

class Cards {
    var cards:          [Card]!
    var userDefaults:   NSUserDefaults!
    
    class func sharedInstance() -> Cards {
        return _cards
    }
    
    init() {
        userDefaults = NSUserDefaults(suiteName: "group.com.roymckenzie.flashcards")
        if let data = userDefaults.objectForKey("cards") as? NSData {
            NSKeyedUnarchiver.setClass(Card.self, forClassName: "Card")
            cards = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [Card]
        }else{
            cards = []
        }
    }
    
    func addCard(card: Card) {
        self.cards.append(card)
        saveCards()
    }
    
    func updateCard(card: Card) {
        for (index, _card) in enumerate(cards) {
            if _card == card {
                cards.removeAtIndex(index)
                cards.append(card)
            }
        }
        saveCards()
    }
    
    func destroyCard(card: Card) {
        for (index, _card) in enumerate(cards) {
            if _card == card {
                cards.removeAtIndex(index)
            }
        }
        saveCards()
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
    
    func saveCards() {
        NSKeyedArchiver.setClassName("Card", forClass: Card.self)
        let data = NSKeyedArchiver.archivedDataWithRootObject(cards)
        userDefaults.setObject(data, forKey: "cards")
        userDefaults.synchronize()
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
        userDefaults.synchronize()
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
        saveCards()
    }
}