//
//  WatchMessage.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/1/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import Foundation

enum WatchMessage {
    case requestStacks
    case requestCards(stackId: String)
    
    var message: [String: Any] {
        switch self {
        case .requestStacks:
            return [description: ""]
        case .requestCards(let stackId):
            return [description: stackId]
        }
    }
    
    func reply(object: Any) -> [String: Any] {
        switch self {
        case .requestStacks:
            guard let stacks = object as? [Stack] else {
                assert(false, "Stacks not found for reply")
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
            }
            let cardInfo: [Dictionary<String, String>] = cards.flatMap { card in
                return  [
                    "frontText": card.frontText ?? "",
                    "backText": card.backText ?? "",
                    "id": card.id
                ]
            }
            return [description: cardInfo]
        }
    }
}

extension WatchMessage: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .requestStacks:
            return "requestStacks"
        case .requestCards:
            return "requestCards"
        }
    }
}
