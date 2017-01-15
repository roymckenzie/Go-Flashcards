//
//  FlashCardsInterfaceController.swift
//  FlashCards WatchKit Extension
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class FlashCardsInterfaceController: WKInterfaceController {

    @IBOutlet weak var topicLabel: WKInterfaceLabel!
    @IBOutlet weak var detailsLabel: WKInterfaceLabel!
    @IBOutlet weak var nextCardButton: WKInterfaceButton!
    @IBOutlet weak var showDetailsButton: WKInterfaceButton!
    
    
    var stackId: String!
    
    @IBAction func showDetails() {
        showDetailsButton.setEnabled(false)
        detailsLabel.setHidden(false)
    }
    
    func enableShowButton() {
        showDetailsButton.setEnabled(true)
        detailsLabel.setHidden(true)
    }
    
    var currentIndex = 0
    var currentCardId: String?
    
    var dataSource = [Dictionary<String, String>]()
    
    @IBAction func getCard() {
        if currentIndex < dataSource.count {
            let cardInfo = dataSource[currentIndex]
            currentCardId = cardInfo["id"]
            topicLabel.setText(cardInfo["frontText"])
            detailsLabel.setText(cardInfo["backText"])
            detailsLabel.setHidden(true)
            showDetailsButton.setEnabled(true)
            currentIndex += 1
        }else{
            setNoCard()
        }
    }
    
    @IBAction func hideCard() {
        let session = WCSession.default()
        session.delegate = self
        
        guard let cardId = currentCardId else { return }
        let watchMessage = WatchMessage.masterCard(cardId: cardId)
        session.sendMessage(watchMessage.message, replyHandler: { message in
            guard let mastered = message[watchMessage.description] as? Bool else { return }
            print(mastered)
        }) { error in
            NSLog("Error setting card as mastered \"\(cardId)\": \(error)")
        }
        getCard()
    }
    
    func setNoCard() {
        let totalCardCount = dataSource.count
        if totalCardCount > 0 {
            topicLabel.setText("Nicely done")
            detailsLabel.setText("You've gone through all \(totalCardCount) of your cards. Go into the app to add more or make them visible again.")
        }else{
            topicLabel.setText("Oh...")
            detailsLabel.setText("There are no cards available in this stack. Go into the FlashCards app and start making some cards!")

        }
        detailsLabel.setHidden(false)
        showDetailsButton.setHidden(true)
        nextCardButton.setHidden(true)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard let context = context as? Dictionary<String, String> else { return }
        
        guard let stackId = context["stackId"] else { return }
        
        self.stackId = stackId
        
        let session = WCSession.default()
        session.delegate = self
        
        let watchMessage = WatchMessage.requestCards(stackId: stackId)
        session.sendMessage(watchMessage.message, replyHandler: { [weak self] message in
            guard let cardsInfo = message[watchMessage.description] as? [Dictionary<String, String>] else { return }
            self?.dataSource = cardsInfo
            self?.getCard()
        }) { error in
            NSLog("Error fetching cards for Stack id \"\(self.stackId)\": \(error)")
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

extension FlashCardsInterfaceController: WCSessionDelegate {
    
    @available(watchOSApplicationExtension 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
    }
}
