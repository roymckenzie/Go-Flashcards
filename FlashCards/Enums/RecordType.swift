//
//  RecordType.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/27/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation

enum RecordType: String {
    case card
    case stack
    case stackPreferences
    
    enum Card: String {
        case frontText
        case frontImage
        case backText
        case backImage
        case userCardPreferences
        case stack
    }
    
    enum Stack: String {
        case name
    }
    
    enum StackPreferences: String {
        case orderedJSON
        case masteredJSON
        case stack
    }
}

extension RecordType: CustomStringConvertible {
    
    var description: String {
        return self.rawValue
    }
}
