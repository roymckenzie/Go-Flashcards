//
//  WatchMessage+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/3/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

extension WatchMessage {
    
    func reply(object: Any) -> [String: Any] {
        switch self {
        case .requestStacks:
            guard let stacks = object as? [Stack] else {
                assert(false, "Stacks not found for reply")
                return ["failed": "couldn't form reply"]
            }
            let stackInfo: [Dictionary<String, String>] = stacks.flatMap { stack in
                return  [
                    "name": stack.name,
                    "id": stack.id
                ]
            }
            return [description: stackInfo]
        case .requestCards:
            guard let cards = object as? [Card] else {
                assert(false, "Cards not found for reply")
                return ["failed": "couldn't form reply"]
            }
            let cardInfo: [Dictionary<String, Any?>] = cards.flatMap { card in
                var dic = [String: Any?]()
                dic.updateValue(card.frontText, forKey: "frontText")
                dic.updateValue(card.backText, forKey: "backText")
                if let frontImage = card.frontImage {
                    dic["frontImage"] = UIImageJPEGRepresentation(frontImage, 0.2)
                }
                if let backImage = card.backImage {
                    dic["backImage"] = UIImageJPEGRepresentation(backImage, 0.2)
                }
                dic.updateValue(card.id, forKey: "id")
                return dic
            }
            return [description: cardInfo]
        case .masterCard:
            guard let mastered = object as? Bool else {
                assert(false, "Could not mark card as mastered")
                return ["failed": "couldn't form reply"]
            }
            return [description: mastered]
        }
    }
}
