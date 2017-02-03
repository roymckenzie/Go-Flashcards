//
//  UIView+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/27/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

extension UIView {
    /// Rounds specified corners of a view by creating a layer mask
    func round(corners: UIRectCorner, radius: CGFloat) {
        let radii = CGSize(width: radius, height: radius)
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: radii)
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }

    /// Applies a radius to all corners of a view
    func cornerRadius(_ radius: CGFloat? = nil) {
        let rounded = radius ?? {
            layoutIfNeeded()
            let height = frame.height
            return height/2
            }()
        layer.cornerRadius = rounded
        clipsToBounds = true
    }

    /// adds constraints to fit view into specified superview
    @discardableResult
    func boundInside(superview: UIView) -> (NSLayoutConstraint, NSLayoutConstraint, NSLayoutConstraint, NSLayoutConstraint) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let left = leftAnchor.constraint(equalTo: superview.leftAnchor)
        let top = topAnchor.constraint(equalTo: superview.topAnchor)
        let right = rightAnchor.constraint(equalTo: superview.rightAnchor)
        let bottom = bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        
        left.isActive = true
        top.isActive = true
        right.isActive = true
        bottom.isActive = true
        
        return (left, top, right, bottom)
    }
    
    @discardableResult
    func boundInside(superview: UIView, withSize size: CGSize?) -> (NSLayoutConstraint, NSLayoutConstraint, NSLayoutConstraint, NSLayoutConstraint) {
        
        guard let size = size else {
            return boundInside(superview: superview)
        }

        translatesAutoresizingMaskIntoConstraints = false
        let left = leftAnchor.constraint(equalTo: superview.leftAnchor)
        let top = topAnchor.constraint(equalTo: superview.topAnchor)
        let height = heightAnchor.constraint(equalToConstant: size.height)
        let width = widthAnchor.constraint(equalToConstant: size.width)
        
        left.isActive = true
        top.isActive = true
        height.isActive = true
        width.isActive = true
        
        return (left, top, height, width)
    }
}
