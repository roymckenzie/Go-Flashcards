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
    var card:       Card!
    var subjectId:  Int!
    var editMode:   Bool?
    
    override func viewDidLoad() {
        if editMode == true {
            topicTextField.text = card.topic
            detailsTextView.text = card.details
        }
    }
    
    @IBAction func saveCard(sender: AnyObject) {
        if editMode == true {
            card.topic = topicTextField.text
            card.details = detailsTextView.text
            User.sharedInstance().subject(subjectId).updateCard(card)
        }else{
            let topic       = topicTextField.text
            let details     = detailsTextView.text
            let card        = Card(topic: topic, details: details)
            User.sharedInstance().subject(subjectId).addCard(card)
        }
        
        self.navigationController?.popViewControllerAnimated(true)
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