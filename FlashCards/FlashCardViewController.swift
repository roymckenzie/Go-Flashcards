//
//  FlashCardViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit

class FlashCardViewController: UIViewController {
    
    @IBOutlet weak var topicTextView: UITextView!
    @IBOutlet weak var detailsTextView: UITextView!
    
    @IBAction func saveCard(sender: AnyObject) {
        let topic       = topicTextView.text
        let details     = detailsTextView.text
        
        let card        = Card(topic: topic, details: details)
        
        Cards.sharedInstance().addCard(card)
        
        self.navigationController?.popViewControllerAnimated(true)
    }
}