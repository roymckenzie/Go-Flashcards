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
import RealmSwift
import GameplayKit

private let NoCardsMessage = "There are no cards in this stack.\nGo add some!"
private let MasteredCardsMessage = "All the cards in this stack\nhave been mastered."

final class FlashCardsViewController: UIViewController {
    
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var stacksStatusImageView: UIImageView! {
        didSet {
            stacksStatusImageView.image?.withRenderingMode(.alwaysTemplate)
            stacksStatusImageView.tintColor = .white
        }
    }
    @IBOutlet weak var stackStatusLabel: UILabel!
    @IBOutlet weak var swipeableView: ZLSwipeableView!
    @IBOutlet weak var masteredHelperView: SwipeHelperView!
    @IBOutlet weak var unmasteredHelperView: SwipeHelperView!
    
    var stack: Stack!
    
    var dataSource: Results<Card> {
        return stack.unmasteredCards
    }
    
    var realmNotificationToken: NotificationToken?
    
    deinit {
        stopRealmNotification()
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        
        switch motion {
        case .motionShake:
            shuffleCards()
        default:
            break
        }
    }

    func shuffleCards() {
        
        let unmasteredCards = Array(stack.unmasteredCards)
        
        let shuffledCards: [Card] = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: unmasteredCards) as! [Card]
        
        let realm = try? Realm()
        
        try? realm?.write {
            shuffledCards.enumerated().forEach { index, card in
                card.order = Double(index)
            }
        }
        
        reloadSwipableView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if stack.cards.isEmpty {
            performSegue(withIdentifier: "editStack", sender: stack)
        }
        
        startRealmNotification() { [weak self] _, _ in
            self?.setupView()
            if self?.navigationController?.topViewController != self {
                self?.reloadSwipableView()
            }
        }
        
        setupView()
        reloadSwipableView()

        swipeableView.didSwipe = { [weak self] view, direction, _ in
            
            if direction == .Left {
                guard let cardView = view as? CardView, let cardId = cardView.cardId else { return }
                
                let realm = try! Realm()
                let card = realm.object(ofType: Card.self, forPrimaryKey: cardId)
                
                try? realm.write {
                    card?.modified = Date()
                    card?.mastered = Date()
                }
            }
            
//            self?.previousButton.isEnabled = true
            
            if self?.swipeableView.topView() == nil {
                self?.reloadButton.isHidden = false
            }
            
            self?.hideHelpers()
            self?.updateStackStatusLabel()
        }
        
        
        swipeableView.swiping = { [weak self] _, _, location in
            guard let _self = self else { return }
            
            let targetHelperView: SwipeHelperView
            
            if location.x > 0 {
                targetHelperView = _self.unmasteredHelperView
            } else {
                targetHelperView = _self.masteredHelperView
            }
            
            let x = abs(location.x)
            let alpha = x/100
            
            targetHelperView.alpha = alpha
        }
        
        swipeableView.didCancel = { [weak self] _ in
            self?.hideHelpers()
        }
        
        swipeableView.onlySwipeTopCard = true
    }
    
    private func updateStackStatusLabel() {
        stackStatusLabel.text = ""
        
        if dataSource.count == 0 {
            reloadButton.isHidden = true
            stacksStatusImageView.isHidden = false
            stackStatusLabel.text = MasteredCardsMessage
        }
        
        if stack.cards.count == 0 {
            reloadButton.isHidden = true
            stacksStatusImageView.isHidden = true
            stackStatusLabel.text = NoCardsMessage
        }
    }
    
    func hideHelpers() {
        UIView.animate(withDuration: 0.3) {
            self.masteredHelperView.alpha = 0
            self.unmasteredHelperView.alpha = 0
        }
    }
    
    func setupView() {
        if !stack.isInvalidated {
            title = stack.name
        } else {
            let _ = navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func gotToPreviousCard(_ sender: Any) {
        previousCard()
    }
    
    @IBAction func shuffle(_ sender: Any) {
        shuffleCards()
    }
    
    func previousCard() {
        
        reloadButton.isHidden = true

        swipeableView.rewind()

        if swipeableView.history.count == 0 {
//            previousButton.isEnabled = false
        }

        
    }
    
    func showCardEditor(sender: UIButton) {
        guard let cardView = sender.superview?.superview?.superview as? CardView, let cardId = cardView.cardId else { return }
        
        let stack = self.stack
        let flashCardVC = Storyboard.main.instantiateViewController(FlashCardViewController.self) { vc in
            let realm = try! Realm()
            let card = realm.object(ofType: Card.self, forPrimaryKey: cardId)
            vc.stack = stack
            vc.card = card
        }

        present(flashCardVC, animated: true, completion: nil)
    }
    
    @IBAction func reloadCards(_ sender: AnyObject) {
        reloadSwipableView()
    }
    
    func reloadSwipableView() {
        stacksStatusImageView.isHidden = true
        reloadButton.isHidden = true
        
        updateStackStatusLabel()
        
        var cardIndex = 0
        
        let cardSize = Card.cardSizeFor(view: view)
        
        swipeableView.discardViews()
        swipeableView.numberOfActiveView = 5
        swipeableView.nextView = { [weak self] in
            guard let _self = self else { return nil }
            if cardIndex < _self.dataSource.count {
                
                // Get card
                let card = _self.dataSource[cardIndex]
                
                // Setup `CardView`
                let frame = CGRect(origin: .zero, size: cardSize)
                let cardView = CardView(frame: frame)
                cardView.cardId = card.id
                cardView.frontTextLabel.text = card.frontText
                cardView.backTextLabel.text = card.backText
                cardView.frontImageView.image = card.frontImage
                cardView.backImageView.image = card.backImage
                
                // Set action on edit card button
                cardView.editCardButton.addTarget(_self, action: #selector(_self.showCardEditor), for: .touchUpInside)
                
                // Advance `cardIndex`
                cardIndex += 1
                
                return cardView
            }
            
            return nil
        }
        
        swipeableView.loadViews()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? StackViewController {
            viewController.stack = stack
            viewController.editMode = true
        }
    }
}

extension FlashCardsViewController: RealmNotifiable {}

final class SwipeHelperView: UIView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        alpha = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        cornerRadius()
    }
}

// This stays because the storyboard cannot see
// ZLSwipeableView class for some reason.
final class FCZLSwipeableView: ZLSwipeableView {}
