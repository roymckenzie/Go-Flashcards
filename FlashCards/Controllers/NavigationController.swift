//
//  NavigationController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/3/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    
    var darkViewHeightConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        let darkBg = UIView(frame: .zero)
            darkBg.translatesAutoresizingMaskIntoConstraints = false
            darkBg.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        view.insertSubview(darkBg, belowSubview: navigationBar)
        darkViewHeightConstraint = darkBg.heightAnchor.constraint(equalTo: navigationBar.heightAnchor)
        darkViewHeightConstraint?.isActive = true
        darkBg.widthAnchor.constraint(equalTo: navigationBar.widthAnchor).isActive = true

        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func setNeedsStatusBarAppearanceUpdate() {
        super.setNeedsStatusBarAppearanceUpdate()
        
        let statusBarFrameHeight = UIApplication.shared.statusBarFrame.height
        darkViewHeightConstraint?.constant = statusBarFrameHeight
    }
}
