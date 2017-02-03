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
    case masterCard(cardId: String)
    case requestCard(cardId: String)
    
    var message: [String: Any] {
        switch self {
        case .requestStacks:
            return [description: ""]
        case .requestCards(let stackId):
            return [description: stackId]
        case .masterCard(let cardId):
            return [description: cardId]
        case .requestCard(let cardId):
            return [description: cardId]
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
        case .masterCard:
            return "masterCard"
        case .requestCard:
            return "requestCard"
        }
    }
}
