//
//  StackViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/7/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation
import UIKit
import FlashCardsKit

class StackViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var buttonBottomLayoutGuide: NSLayoutConstraint!
    
    var subject:    Subject!
    var editMode:   Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if editMode == true {
            nameTextField.text = subject.name
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func keyboardDidShow(notification: NSNotification) {
        let info: NSDictionary = notification.userInfo!
        let value: NSValue = info.valueForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardSize: CGSize = value.CGRectValue().size
        buttonBottomLayoutGuide.constant = keyboardSize.height
        
        var curve = info[UIKeyboardAnimationCurveUserInfoKey]!.unsignedIntValue
        
        UIView.animateWithDuration(
            info[UIKeyboardAnimationDurationUserInfoKey]!.doubleValue,
            delay: 0,
            options: UIViewAnimationOptions(UInt(curve)),
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    @IBAction func saveSubject(sender: AnyObject) {
        nameTextField.resignFirstResponder()
        if editMode == true {
            subject.name = nameTextField.text
            User.sharedInstance().updateSubject(subject)
        }else{
            let name        = nameTextField.text
            let _subject    = Subject(name: name)
            User.sharedInstance().addSubject(_subject)
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        nameTextField.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension StackViewController: UITextFieldDelegate, UITextViewDelegate {
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField.text == "Stack name" {
            textField.text = ""
        }
        textField.font = UIFont(name: "Avenir-Heavy", size: 24)
        textField.textColor = UIColor.whiteColor()
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.text == "" {
            textField.text = "Stack name"
            textField.font = UIFont(name: "Avenir-HeavyOblique", size: 24)
            textField.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
            
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        saveSubject(UIButton())
        return false
    }
    
}