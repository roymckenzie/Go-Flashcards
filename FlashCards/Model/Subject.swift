//
//  Subject.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/17/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation

open class OldSubject: NSObject, NSCoding {
    open var cards   = [OldCard]()
    open var id:     Int
    open var name:   String
    
    required public init(coder aDecoder: NSCoder) {
        NSKeyedUnarchiver.setClass(OldCard.classForKeyedUnarchiver(), forClassName: "FlashCardsKit.Card")
        self.cards = aDecoder.decodeObject(forKey: "cards") as? [OldCard] ?? []
        self.id = aDecoder.decodeInteger(forKey: "id")
        self.name = aDecoder.decodeObject(forKey: "name") as? String ?? ""
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(cards, forKey: "cards")
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
    }
}
