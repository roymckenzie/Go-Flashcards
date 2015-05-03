//
//  FlashCardViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit

class FlashCardViewController: UIViewController {
    
    @IBOutlet weak var questionTextView: UITextView!
    @IBOutlet weak var answerTextView: UITextView!
    
    @IBAction func saveCard(sender: AnyObject) {
        let question    = questionTextView.text
        let answer      = answerTextView.text
        
        let card        = Card(answer: answer, question: question)
        
        Cards.sharedInstance().addCard(card)
        
        self.navigationController?.popViewControllerAnimated(true)
    }
}