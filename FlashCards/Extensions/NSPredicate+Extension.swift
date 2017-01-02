//
//  NSPredicate+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/31/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation

extension NSPredicate {
    
    /// a `NSPredicate` object of `init.(value: true)`
    static var truePredicate: NSPredicate {
        return NSPredicate(value: true)
    }
}
