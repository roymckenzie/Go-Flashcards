//
//  ViewNibNestable.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/27/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

protocol ViewNibNestable: class {
    
    /// left, top, height, width
    var reusableViewLayoutConstraints: (NSLayoutConstraint, NSLayoutConstraint, NSLayoutConstraint, NSLayoutConstraint)? { get set }
    func reuseView() -> UIView
}

extension ViewNibNestable where Self: UIView {
    func reuseView() -> UIView {
        return reuseViewWithClass(classNamed: Self.self)
    }
    
    func reuseView(withSize size: CGSize? = nil) -> UIView {
        return reuseViewWithClass(classNamed: Self.self, size: size)
    }
    
    private func reuseViewWithClass(classNamed: UIView.Type, size: CGSize? = nil) -> UIView {
        let nibName = String(describing: classNamed)
        guard let nibViews = Bundle.main.loadNibNamed(nibName,
                                                      owner: self,
                                                      options: [:]) as? [UIView] else {
                                                        return UIView()
        }
        guard let loadedView = nibViews.first else {
            return UIView()
        }
        
        addSubview(loadedView)
        loadedView.translatesAutoresizingMaskIntoConstraints = false
        reusableViewLayoutConstraints = loadedView.boundInside(superview: self, withSize: size)
        return loadedView
    }
}
