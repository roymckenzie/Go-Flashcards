//
//  CardSide.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/30/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

enum CardSide {
    case front, back
    
    var nextSide: CardSide {
        return self == .front ? .back : .front
    }
    
    var transitionDirectionAnimationOption: UIViewAnimationOptions {
        return self == .front ? .transitionFlipFromRight : .transitionFlipFromLeft
    }
}
