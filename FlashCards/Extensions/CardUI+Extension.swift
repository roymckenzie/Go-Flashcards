//
//  CardUI+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/30/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

// MARK:- UI Card stuff
extension Card {
    
    static func cardSizeFor(view: UIView) -> CGSize {
        let width: CGFloat
        let height: CGFloat
        switch view.traitCollection.horizontalSizeClass {
        case .unspecified:
            fallthrough
        case .compact:
            width = view.frame.size.width - 40
            height = width * 1.66
        case .regular:
            width = view.frame.size.width - 100
            height = width * 1.33
        }
        return CGSize(width: width, height: height)
    }
}
