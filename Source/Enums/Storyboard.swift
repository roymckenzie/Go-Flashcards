//
//  Storyboard.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/28/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

enum Storyboard: String {
    case main
    
    struct Identifier {
        static let myStacksNavigationController = "MyStacksNavigationController"
    }
}

extension Storyboard: CustomStringConvertible {
    
    var description: String {
        return self.rawValue.capitalized
    }
}

extension Storyboard {
    
    private var storyboard: UIStoryboard {
        return UIStoryboard(name: self.description, bundle: nil)
    }
    
    func instantiateViewController<T: UIViewController>(_ className: T.Type, completion: ((T) -> Void)? = nil) -> T {
        let vc = storyboard.instantiateViewController(withIdentifier: "\(className)") as! T
        completion?(vc)
        return vc
    }
    
    func instantiateViewController(with identifier: String) -> UIViewController {
        return storyboard.instantiateViewController(withIdentifier: identifier)
    }
}
