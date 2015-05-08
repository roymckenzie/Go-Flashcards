//
//  FlashCardsInterfaceController.swift
//  FlashCards WatchKit Extension
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import FlashCardsKit
import WatchKit
import Foundation


class FlashCardsInterfaceController: WKInterfaceController {

    @IBOutlet weak var topicLabel: WKInterfaceLabel!
    @IBOutlet weak var detailsLabel: WKInterfaceLabel!
    @IBOutlet weak var seperatorView: WKInterfaceSeparator!
    @IBOutlet weak var nextCardButton: WKInterfaceButton!
    @IBOutlet weak var showDetailsButton: WKInterfaceButton!
    var _card:          Card!
    var _subject:       Subject!
    var _subjectId:     Int!
    
    @IBAction func showDetails() {
        showDetailsButton.setEnabled(false)
        seperatorView.setHidden(false)
        detailsLabel.setHidden(false)
    }
    
    func enableShowButton() {
        showDetailsButton.setEnabled(true)
        seperatorView.setHidden(true)
        detailsLabel.setHidden(true)
    }
    
    @IBAction func getCard() {
        if let card = User.sharedInstance().subject(_subjectId).getRandomCard() {
            _card = card
            self.topicLabel.setText(card.topic)
            self.detailsLabel.setText(card.details)
            self.detailsLabel.setHidden(true)
            self.seperatorView.setHidden(true)
            showDetailsButton.setEnabled(true)
        }else{
            setNoCard()
        }
    }
    
    @IBAction func hideCard() {
        _subject.hideCard(_card)
        getCard()
    }
    
    func setNoCard() {
        let visibleCardCount = _subject.visibleCards().count
        let totalCardCount = _subject.cards.count
        topicLabel.setText("Oops!")
        if totalCardCount > 0 {
            detailsLabel.setText("You've gone through all \(totalCardCount) of your cards. Go into the app to add more or make them visible again.")
        }else{
            detailsLabel.setText("There are no cards available in this subject. Go into the FlashCards app and start making some cards!")

        }
        detailsLabel.setHidden(false)
        seperatorView.setHidden(false)
        showDetailsButton.setHidden(true)
        nextCardButton.setHidden(true)
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let _context = context as? NSDictionary {
            _subjectId = _context["subjectId"] as! Int
            _subject = User.sharedInstance().subject(_subjectId)
            getCard()
        }else{
            setNoCard()
        }

    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
