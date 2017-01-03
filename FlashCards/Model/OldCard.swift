//
//  OldCard.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/26/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation

open class OldCard: NSObject, NSCoding {
    var topic: String = ""
    var detail: String = ""
    var hidden: Bool = false
    var order: Int = 0
    
    required public init(coder aDecoder: NSCoder) {
        NSKeyedUnarchiver.setClass(OldCard.classForKeyedUnarchiver(), forClassName: "FlashCardsKit.Card")
        NSKeyedUnarchiver.setClass(OldSubject.classForKeyedUnarchiver(), forClassName: "FlashCardsKit.Subject")
        
        self.detail    = aDecoder.decodeObject(forKey: "details") as? String ?? ""
        self.topic     = aDecoder.decodeObject(forKey: "topic") as? String ?? ""
        self.hidden     = aDecoder.decodeObject(forKey: "hidden") as? Bool ?? false
        self.order     = aDecoder.decodeObject(forKey: "order") as? Int ?? 0
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(detail, forKey: "details")
        aCoder.encode(topic, forKey: "topic")
        aCoder.encode(hidden, forKey: "hidden")
        aCoder.encode(order, forKey: "order")
    }
}
