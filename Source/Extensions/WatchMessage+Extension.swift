//
//  WatchMessage+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/3/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit
import SDWebImage

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
            let cardIds = cards.flatMap { $0.id }
            return [description: cardIds]
        case .masterCard:
            guard let mastered = object as? Bool else {
                assert(false, "Could not mark card as mastered")
                return ["failed": "couldn't form reply"]
            }
            return [description: mastered]
        case .requestCard:
            guard let card = object as? Card else {
                assert(false, "Could not mark card as mastered")
                return ["failed": "couldn't form reply"]
            }
            var cardDic = [String: Any?]()
            cardDic.updateValue(card.frontText, forKey: "frontText")
            cardDic.updateValue(card.backText, forKey: "backText")
            if let frontImage = try? card.frontImage?.resizeImageForStorage(targetWidth: 312) {
                if let image = frontImage {
                    cardDic["frontImage"] = UIImageJPEGRepresentation(image, 0.1)
                }
            }
            if let backImage = try? card.backImage?.resizeImageForStorage(targetWidth: 312) {
                if let image = backImage {
                    cardDic["backImage"] = UIImageJPEGRepresentation(image, 0.1)
                }
            }
            cardDic.updateValue(card.id, forKey: "id")
            return [description: cardDic]
        }
    }
}
