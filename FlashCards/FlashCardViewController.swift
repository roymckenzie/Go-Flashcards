//
//  FlashCardViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit

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
        
        NotificationCenter.default.addObserver(self, selector: #selector(FlashCardViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func keyboardDidShow(_ notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        let value: NSValue = info.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardSize: CGSize = value.cgRectValue.size
        buttonBottomLayoutGuide.constant = keyboardSize.height
        
        UIView.animate(withDuration: 0.2,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    @IBAction func saveCard(_ sender: AnyObject) {
        topicTextField.resignFirstResponder()
        detailsTextView.resignFirstResponder()
        if editMode == true {
            card.topic = topicTextField.text ?? ""
            card.details = detailsTextView.text ?? ""
            subject.updateCard(card)
        }else{
            guard let topic       = topicTextField.text,
                  let details     = detailsTextView.text else { return }
            let card        = Card(subject: subject, topic: topic, details: details)
            subject.addCard(card)
        }
        
        self.dismiss(animated: true, completion: { () -> Void in
            self._cardViewDelegate?.topicLabel.text = self.topicTextField.text
            self._cardViewDelegate?.detailLabel.text = self.detailsTextView.text
        })
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        topicTextField.resignFirstResponder()
        detailsTextView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
}

extension FlashCardViewController: UITextFieldDelegate, UITextViewDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == "Topic" {
            textField.text = ""
        }
        textField.font = UIFont(name: "Avenir-Heavy", size: 24)
        textField.textColor = UIColor.white
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == "" {
            textField.text = "Topic"
            textField.font = UIFont(name: "Avenir-HeavyOblique", size: 24)
            textField.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)

        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        detailsTextView.becomeFirstResponder()
        return false
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Details" {
            textView.text = ""
        }
        textView.font = UIFont(name: "Avenir-Book", size: 20)
        textView.textColor = UIColor.white
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "Details"
            textView.font = UIFont(name: "Avenir-BookOblique", size: 20)
            textView.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        }

    }
}

class PopopverUINavigationBar: UINavigationBar {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let navBar = self
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.tintColor = UIColor.white
        
        let navBarFrame = navBar.frame
        let newFrame = CGRect(x: 0, y: 0, width: navBarFrame.width, height: navBarFrame.height)
        let darkBg = UIView(frame: newFrame)
        darkBg.backgroundColor = UIColor.black
        darkBg.alpha = 0.4
        
        self.insertSubview(darkBg, at: 0)
        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName:UIFont(name: "Avenir", size: 15)!], for: UIControlState())
    }

}
