//
//  FlashCardViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit
import FlashCardsKit


class FlashCardViewController: UIViewController {
    
    @IBOutlet weak var topicTextField: UITextField!
    @IBOutlet weak var detailsTextView: UITextView!
    @IBOutlet weak var buttonBottomLayoutGuide: NSLayoutConstraint!

    var card:       Card!
    var subject:    Subject!
    var editMode:   Bool?
    weak var _cardViewDelegate: CardView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if editMode == true {
            topicTextField.text = card.topic
            detailsTextView.text = card.details
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
    
    @IBAction func saveCard(sender: AnyObject) {
        topicTextField.resignFirstResponder()
        detailsTextView.resignFirstResponder()
        if editMode == true {
            card.topic = topicTextField.text
            card.details = detailsTextView.text
            subject.updateCard(card)
        }else{
            let topic       = topicTextField.text
            let details     = detailsTextView.text
            let card        = Card(subject: subject, topic: topic, details: details)
            subject.addCard(card)
        }
        
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            self._cardViewDelegate?.topicLabel.text = self.topicTextField.text
            self._cardViewDelegate?.detailLabel.text = self.detailsTextView.text
        })
    }
    
    @IBAction func cancel(sender: AnyObject) {
        topicTextField.resignFirstResponder()
        detailsTextView.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension FlashCardViewController: UITextFieldDelegate, UITextViewDelegate {
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField.text == "Topic" {
            textField.text = ""
        }
        textField.font = UIFont(name: "Avenir-Heavy", size: 24)
        textField.textColor = UIColor.whiteColor()
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.text == "" {
            textField.text = "Topic"
            textField.font = UIFont(name: "Avenir-HeavyOblique", size: 24)
            textField.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)

        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        detailsTextView.becomeFirstResponder()
        return false
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == "Details" {
            textView.text = ""
        }
        textView.font = UIFont(name: "Avenir-Book", size: 20)
        textView.textColor = UIColor.whiteColor()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            textView.text = "Details"
            textView.font = UIFont(name: "Avenir-BookOblique", size: 20)
            textView.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        }

    }
}

class PopopverUINavigationBar: UINavigationBar {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let navBar = self
        navBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navBar.tintColor = UIColor.whiteColor()
        
        let navBarFrame = navBar.frame
        let newFrame = CGRect(x: 0, y: 0, width: navBarFrame.width, height: navBarFrame.height)
        let darkBg = UIView(frame: newFrame)
        darkBg.backgroundColor = UIColor.blackColor()
        darkBg.alpha = 0.4
        
        self.insertSubview(darkBg, atIndex: 0)
        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName:UIFont(name: "Avenir", size: 15)!], forState: UIControlState.Normal)
    }

}