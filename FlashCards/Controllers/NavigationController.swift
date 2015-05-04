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
        let navBar = self.navigationBar
            navBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
            navBar.tintColor = UIColor.whiteColor()
        
        let statusBarFrame = UIApplication.sharedApplication().statusBarFrame
        let navBarFrame = navBar.frame
        let newHeight = statusBarFrame.height + navBarFrame.height
        
        let newFrame = CGRect(x: 0, y: 0, width: navBarFrame.width, height: newHeight)
        let darkBg = UIView(frame: newFrame)
            darkBg.backgroundColor = UIColor.blackColor()
            darkBg.alpha = 0.4
        
        self.view.insertSubview(darkBg, belowSubview: self.navigationBar)

        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName:UIFont(name: "Avenir", size: 15)!], forState: UIControlState.Normal)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}