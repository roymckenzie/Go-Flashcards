//
//  NavigationController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/3/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let navBar = self.navigationBar
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.tintColor = UIColor.white
        
        let statusBarFrame = UIApplication.shared.statusBarFrame
        let navBarFrame = navBar.frame
        let newHeight = statusBarFrame.height + navBarFrame.height
        
        let newFrame = CGRect(x: 0, y: 0, width: navBarFrame.width, height: newHeight)
        let darkBg = UIView(frame: newFrame)
            darkBg.backgroundColor = UIColor.black
            darkBg.alpha = 0.4
        
        self.view.insertSubview(darkBg, belowSubview: self.navigationBar)

        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName:UIFont(name: "Avenir", size: 15)!], for: UIControlState())
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}
