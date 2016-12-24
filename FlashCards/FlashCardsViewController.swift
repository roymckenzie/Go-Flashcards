//
//  FlashCardsViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/27/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation
import UIKit
import ZLSwipeableViewSwift

class FlashCardsViewController: UIViewController {
    
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var stackStatusLabel: UILabel!
    @IBOutlet var swipeableView: ZLSwipeableView!
    
    var stack: Stack!
    var cardIndex = 0
    var initialLoad = false
    var swipedViews: [(view: UIView, vector: CGVector)] = []
    let noCardsMessage = "There are no cards in this stack.\nGo add some!"
    let noVisibleCardsMessage = "All the cards in this stack are hidden.\nGo make some visible!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = stack.name
        
        stack.fetchCards()
            .then { [weak self] cards in
                self?.stack.cards = cards
                self?.reloadCards(UIButton())
            }
            .catch { [weak self] error in
                self?.showAlert(title: "Could not fetch cards", error: error)
            }
        
        swipeableView.didSwipe = {view, direction, vector in
            guard let cardView = view.subviews.first as? CardView,
                      let card = cardView.card else { return }
            
            if vector.dx < 0 {
//                self.subject.hideCard(card)
            }
            
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            
            if self.swipeableView.topView() == nil {
                self.reloadButton.isHidden = false
            }
            
            self.swipedViews.append(view: view, vector: vector)

        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(FlashCardsViewController.previousCard))
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    func previousCard() {
        
        reloadButton.isHidden = true
        let view = swipedViews.last
        guard let cardView = view?.view.subviews.first as? CardView,
                  let card = cardView.card else { return }
        swipedViews.removeLast()
        cardView.hideDetails()
        

        
        if swipedViews.count == 0 {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        if view!.vector.dx < 0 {
//            card.subject.unHideCard(card)
        }
        
        swipeableView.rewind()
    }
    
    @IBAction func reloadCards(_ sender: AnyObject) {
        swipedViews.removeAll()
        navigationItem.rightBarButtonItem?.isEnabled = false
        reloadButton.isHidden = true
        cardIndex = 0
        swipeableView.discardViews()
        swipeableView.numberOfActiveView = 5
        swipeableView.nextView = {
//            if self.cardIndex < self.subject.visibleCards().count {
            if self.cardIndex < self.stack.cards.count {
                let card = self.stack.cards[self.cardIndex]
                let frame = CGRect(x: 0, y: -50, width: self.swipeableView.frame.width-50, height: self.swipeableView.frame.height-50)
                let cardView = CardView(frame: frame)
                let cardContentView = Bundle.main.loadNibNamed("CardView", owner: self, options: nil)?.first as! CardView
                cardContentView.card = card
                cardContentView._flashCardsViewDelegate = self
                cardContentView.setup()
                
                cardView.addSubview(cardContentView)

                let metrics = ["width":cardView.bounds.width, "height": cardView.bounds.height]
                let views = ["cardContentView": cardContentView, "cardView": cardView]
                cardView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[cardContentView(width)]", options: .alignAllLeft, metrics: metrics, views: views))
                cardView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[cardContentView(height)]", options: .alignAllLeft, metrics: metrics, views: views))
                
                
                self.cardIndex += 1
                return cardView
            }
            return nil
        }
        swipeableView.loadViews()
        
//        if subject.visibleCards().count == 0 {
//            stackStatusLabel.text = noVisibleCardsMessage
//            stackStatusLabel.isHidden = false
//        }
        
        stackStatusLabel.text = noCardsMessage
        stackStatusLabel.isHidden = stack.cards.count > 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
    var card: NewCard!
    
    func setup() {
        // Resize to parent view
        translatesAutoresizingMaskIntoConstraints = false
        
        // Background color
        backgroundColor = UIColor.midGreenColor()
        
        // Border
        layer.borderColor = UIColor.darkGreenColor().cgColor
        layer.borderWidth = 2.0
        layer.cornerRadius = 2.0
        
        // Labels
        topicLabel.text = card.topic
        detailLabel.text = card.details
    }
    
    @IBAction func editCard(_ sender: AnyObject) {
        let flashCardVC = _flashCardsViewDelegate.storyboard?.instantiateViewController(withIdentifier: "flashCardVC") as! FlashCardViewController
        flashCardVC.card = card
        flashCardVC.editMode = true
        flashCardVC._cardViewDelegate = self
        _flashCardsViewDelegate.present(flashCardVC, animated: true, completion: nil)
    }
    
    @IBAction func showDetails(_ sender: AnyObject) {
        showButton.isHidden = true
        detailLabel.isHidden = false
        editCardButton.isHidden = false
    }
    
    func hideDetails() {
        showButton.isHidden = false
        detailLabel.isHidden = true
        editCardButton.isHidden = true
    }
}

class RevealButton: UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.cornerRadius = self.frame.width/2
    }
}

final class FCZLSwipeableView: ZLSwipeableView {
    
}
