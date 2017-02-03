//
//  KeyboardAvoidable.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/28/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

protocol KeyboardAvoidable: class {
    func addKeyboardListeners(customBlock: ((CGFloat) -> Void)?)
    func removeKeyboardListeners()
    var layoutConstraintsToAdjust: [NSLayoutConstraint] { get }
}

var KeyboardShowListenerObjectKey: UInt8 = 1
var KeyboardHideListenerObjectKey: UInt8 = 2

extension KeyboardAvoidable where Self: UIViewController {
    
    var keyboardShowListenerObject: NSObjectProtocol? {
        get {
            return objc_getAssociatedObject(self,
                                            &KeyboardShowListenerObjectKey) as? NSObjectProtocol
        }
        set {
            
            objc_setAssociatedObject(self,
                                     &KeyboardShowListenerObjectKey,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var keyboardHideListenerObject: NSObjectProtocol? {
        get {
            return objc_getAssociatedObject(self,
                                            &KeyboardHideListenerObjectKey) as? NSObjectProtocol
        }
        set {
            
            objc_setAssociatedObject(self,
                                     &KeyboardHideListenerObjectKey,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func addKeyboardListeners(customBlock: ((CGFloat) -> Void)? = nil) {
        keyboardShowListenerObject = NotificationCenter.default.addObserver(forName: .UIKeyboardWillShow,
                                                                            object: nil,
                                                                            queue: nil)
        { [weak self] notification in
                                                                            
            guard let height = self?.getKeyboardHeightFrom(notification: notification) else { return }
            
            if let customBlock = customBlock {
                customBlock(height)
                return
            }
            
            self?.layoutConstraintsToAdjust.forEach {
                $0.constant = height
            }
            
            UIView.animate(withDuration: 0.2){
                self?.view.layoutIfNeeded()
            }
        }
        
        keyboardHideListenerObject = NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide,
                                                                            object: nil,
                                                                            queue: nil)
        { [weak self] notification in
                                                                            
            if let customBlock = customBlock {
                customBlock(0)
                return
            }
            
            self?.layoutConstraintsToAdjust.forEach {
                $0.constant = 0
            }
            
            UIView.animate(withDuration: 0.2){
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    private func getKeyboardHeightFrom(notification: Notification) -> CGFloat {
        guard let info = notification.userInfo else { return .leastNormalMagnitude }
        guard let value = info[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return .leastNormalMagnitude }
        let keyboardSize = value.cgRectValue.size
        return keyboardSize.height
    }
    
    func removeKeyboardListeners() {
        if let keyboardShowListenerObject = keyboardShowListenerObject {
            NotificationCenter.default.removeObserver(keyboardShowListenerObject)
        }
        if let keyboardHideListenerObject = keyboardHideListenerObject {
            NotificationCenter.default.removeObserver(keyboardHideListenerObject)
        }
        keyboardShowListenerObject = nil
        keyboardHideListenerObject = nil
    }
}
