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
    case userCardPreferences
    
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
    
    enum UserCardPreferences: String {
        case order
        case mastered
        case card
    }
}

extension RecordType: CustomStringConvertible {
    
    var description: String {
        return self.rawValue
    }
}
