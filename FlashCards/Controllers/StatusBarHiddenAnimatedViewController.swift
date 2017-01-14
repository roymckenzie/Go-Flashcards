//
//  StatusBarHiddenAnimatedViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/8/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

class StatusBarHiddenAnimatedViewController: UIViewController {
    
    var statusBarHidden = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        statusBarHidden = true
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        statusBarHidden = false
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    override func setNeedsStatusBarAppearanceUpdate() {
        UIView.animate(withDuration: 0.33) {
            super.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    deinit {
        NSLog("StatusBarHiddenViewController deinit")
    }    
}
