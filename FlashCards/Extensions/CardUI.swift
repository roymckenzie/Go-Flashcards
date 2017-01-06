//
//  CardUI.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/30/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

// MARK:- UI Card stuff
struct CardUI {
    
    static func editCardSizeFor(view: UIView) -> CGSize {
        let width: CGFloat
        let height: CGFloat
        
        // Width, Height
        switch (view.traitCollection.horizontalSizeClass, view.traitCollection.verticalSizeClass) {
        case (.unspecified, .unspecified):
            fallthrough
        case (.compact, .regular):
            width = view.frame.width - 70
            height = width * 1.66
        case (.regular, .regular):
            height = view.frame.height * 0.8
            width = height * 0.66
        case (.compact, .compact):
            width = view.frame.width - 40
            height = view.frame.height - 40
        default:
            width = view.frame.width - 40
            height = view.frame.height - 40
        }
        return CGSize(width: width, height: height)
    }

    
    static func cardSizeFor(view: UIView) -> CGSize {
        let width: CGFloat
        let height: CGFloat
        
        // Width, Height
        switch (view.traitCollection.horizontalSizeClass, view.traitCollection.verticalSizeClass) {
        case (.unspecified, .unspecified):
            fallthrough
        case (.compact, .regular):
            width = view.frame.width - 40
            height = width * 1.66
        case (.regular, .regular):
            height = view.frame.height * 0.8
            width = height * 0.66
        case (.compact, .compact):
            width = view.frame.width - 40
            height = view.frame.height - 40
        default:
            width = view.frame.width - 40
            height = view.frame.height - 40
        }
        return CGSize(width: width, height: height)
    }
}
