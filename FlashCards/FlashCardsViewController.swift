//
//  FlashCardsViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/27/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation
import UIKit
import FlashCardsKit

class FlashCardsViewController: UIViewController {
    
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var stackStatusLabel: UILabel!
    @IBOutlet var swipeableView: ZLSwipeableView!
    var subject: Subject!
    var cardIndex = 0
    var initialLoad = false
    var swipedViews: [(view: UIView, vector: CGVector)] = []
    let noCardsMessage = "There are no cards in this stack.\nGo add some!"
    let noVisibleCardsMessage = "All the cards in this stack are hidden.\nGo make some visible!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = subject.name
        
        swipeableView.didSwipe = {view, direction, vector in
            let card = (view.subviews.first as! CardView).card

            if vector.dx < 0 {
                self.subject.hideCard(card)
            }
            
            self.navigationItem.rightBarButtonItem?.enabled = true
            
            if self.swipeableView.topView() == nil {
                self.reloadButton.hidden = false
            }
            
            self.swipedViews.append(view: view, vector: vector)

        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "previousCard")
        navigationItem.rightBarButtonItem?.enabled = false
    }
    
    func previousCard() {
        reloadButton.hidden = true
        let view = swipedViews.last
        swipedViews.removeLast()
        let card = (view!.view.subviews.first as! CardView).card
        (view!.view.subviews.first as! CardView).hideDetails()
        

        
        if swipedViews.count == 0 {
            navigationItem.rightBarButtonItem?.enabled = false
        }
        
        let width = self.swipeableView.bounds.width
        let height = self.swipeableView.bounds.height
        var point: CGPoint!
        
        if view!.vector.dx < 0 {
            point = CGPoint(x: -width, y: height/2)
            card.subject.unHideCard(card)
        }else{
            point = CGPoint(x: width*2, y: height/2)
        }
        
        swipeableView.insertTopView(view!.view, fromPoint: point)
    }
    
    @IBAction func reloadCards(sender: AnyObject) {
        swipedViews.removeAll()
        navigationItem.rightBarButtonItem?.enabled = false
        reloadButton.hidden = true
        cardIndex = 0
        swipeableView.discardViews()
        swipeableView.numPrefetchedViews = 5
        swipeableView.nextView = {
            if self.cardIndex < self.subject.visibleCards().count {
                let card = self.subject.visibleCards()[self.cardIndex]
                let frame = CGRectMake(0, -50, self.swipeableView.frame.width-50, self.swipeableView.frame.height-50)
                let cardView = CardView(frame: frame)
                let cardContentView = NSBundle.mainBundle().loadNibNamed("CardView", owner: self, options: nil).first as! CardView
                cardContentView.card = card
                cardContentView._flashCardsViewDelegate = self
                cardContentView.setup()
                
                cardView.addSubview(cardContentView)

                let metrics = ["width":cardView.bounds.width, "height": cardView.bounds.height]
                let views = ["cardContentView": cardContentView, "cardView": cardView]
                cardView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[cardContentView(width)]", options: .AlignAllLeft, metrics: metrics, views: views))
                cardView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[cardContentView(height)]", options: .AlignAllLeft, metrics: metrics, views: views))
                
                
                self.cardIndex++
                return cardView
            }
            return nil
        }
        swipeableView.loadViews()
        
        if subject.visibleCards().count == 0 {
            stackStatusLabel.text = noVisibleCardsMessage
            stackStatusLabel.hidden = false
        }
        
        if subject.cards.count == 0 {
            stackStatusLabel.text = noCardsMessage
            stackStatusLabel.hidden = false
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !initialLoad {
            reloadCards(UIButton())
            initialLoad = true
        }
    }
}

class CardView: UIView {
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var editCardButton: UIButton!
    
    weak var _flashCardsViewDelegate: FlashCardsViewController!
    var card: Card!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setup() {
        // Resize to parent view
        setTranslatesAutoresizingMaskIntoConstraints(false)
        
        // Background color
        backgroundColor = UIColor.midGreenColor()
        
        // Border
        layer.borderColor = UIColor.darkGreenColor().CGColor
        layer.borderWidth = 2.0
        layer.cornerRadius = 2.0
        
        // Labels
        topicLabel.text = card.topic
        detailLabel.text = card.details
    }
    
    @IBAction func editCard(sender: AnyObject) {
        let flashCardVC = _flashCardsViewDelegate.storyboard?.instantiateViewControllerWithIdentifier("flashCardVC") as! FlashCardViewController
        flashCardVC.card = card
        flashCardVC.subject = card.subject
        flashCardVC.editMode = true
        flashCardVC._cardViewDelegate = self
        _flashCardsViewDelegate.presentViewController(flashCardVC, animated: true, completion: nil)
    }
    
    @IBAction func showDetails(sender: AnyObject) {
        showButton.hidden = true
        detailLabel.hidden = false
        editCardButton.hidden = false
    }
    
    func hideDetails() {
        showButton.hidden = false
        detailLabel.hidden = true
        editCardButton.hidden = true
    }
}

class RevealButton: UIButton {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.cornerRadius = self.frame.width/2
    }
}
