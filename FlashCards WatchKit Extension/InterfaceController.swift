//
//  InterfaceController.swift
//  FlashCards WatchKit Extension
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var topicLabel: WKInterfaceLabel!
    @IBOutlet weak var detailsLabel: WKInterfaceLabel!
    @IBOutlet weak var seperatorView: WKInterfaceSeparator!
    @IBOutlet weak var nextCardButton: WKInterfaceButton!
    @IBOutlet weak var showDetailsButton: WKInterfaceButton!
    var _card: Card!
    
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
        let userInfo = ["request":"getCard"]
        WKInterfaceController.openParentApplication(userInfo, reply: { (response:[NSObject : AnyObject]!, error:NSError!) -> Void in
            if let response = response, card = response["card"] as? NSData {
                NSKeyedUnarchiver.setClass(Card.self, forClassName: "Card")
                self._card = NSKeyedUnarchiver.unarchiveObjectWithData(card) as! Card
                self.topicLabel.setText(self._card.topic)
                self.detailsLabel.setText(self._card.details)
                self.nextCardButton.setHidden(false)
                self.enableShowButton()
            }else{
                self.setNoCard()
            }
        })
    }
    
    @IBAction func hideCard() {
        if let cardId = _card?.id {
            let userInfo = ["hideCard":_card.id]
            WKInterfaceController.openParentApplication(userInfo, reply: { (response:[NSObject : AnyObject]!, error:NSError!) -> Void in
                if let response = response, card = response["card"] as? NSData {
                    NSKeyedUnarchiver.setClass(Card.self, forClassName: "Card")
                    self._card = NSKeyedUnarchiver.unarchiveObjectWithData(card) as! Card
                    self.topicLabel.setText(self._card.topic)
                    self.detailsLabel.setText(self._card.details)
                    self.nextCardButton.setHidden(false)
                    self.enableShowButton()
                }else{
                    self.setNoCard()
                }
            })
        }
    }
    
    func setNoCard() {
        topicLabel.setText("Oops!")
        detailsLabel.setText("There are no cards available. Go into the FlashCards app and start making some cards!")
        detailsLabel.setHidden(false)
        seperatorView.setHidden(false)
        showDetailsButton.setEnabled(false)
    }
    
    @IBAction func cancel() {
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        // Configure interface objects here.
        self.topicLabel.setText(" ")
        self.detailsLabel.setText(" ")
        self.seperatorView.setHidden(true)
        getCard()
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
