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

private let NoCardsMessage = NSLocalizedString("There are no cards in this stack.\nGo add some!", comment: "No cards in the stack")
private let MasteredCardsMessage = NSLocalizedString("All the cards in this stack\nhave been mastered.", comment: "All cards in this stack mastered")

final class FlashCardsViewController: UIViewController {
    
    @IBOutlet weak var stacksStatusImageView: UIImageView!
    @IBOutlet weak var stackStatusLabel: UILabel!
    @IBOutlet weak var swipeableView: FCZLSwipeableView!
    @IBOutlet weak var masteredHelperView: SwipeHelperView!
    @IBOutlet weak var stackTitleLabel: UILabel!
    @IBOutlet weak var stackDetailsLabel: UILabel!
    @IBOutlet weak var previousButton: UIBarButtonItem!
    @IBOutlet weak var shuffleButton: UIBarButtonItem!
    @IBOutlet weak var progressBar: ProgressBar!
    
    override var title: String? {
        didSet {
            stackTitleLabel.text = title
        }
    }
    
    var nextCardIndex = 0
    var firstLoadHappened = false
    var realmNotificationToken: NotificationToken?
    var stack: Stack!
    var didSwipe = false
    
    var dataSource: Results<Card> {
        return stack.unmasteredCards
    }
    
    deinit {
        stopRealmNotification()
        NSLog("[FlashCardsViewController] deinit")
    }
    
    // MARK:- Override supers
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if stack.cards.isEmpty {
            performSegue(withIdentifier: "editStack", sender: stack)
        }
        swipeableView.alpha = 0
        
        startRealmNotification() { [weak self] _, _ in
            guard let _self = self else { return }
            if _self.stack.isInvalidated ||  _self.stack.cards.isInvalidated {
                let _ = _self.navigationController?.popToRootViewController(animated: true)
                return
            }
            _self.setupView()
            if  _self.navigationController?.topViewController != _self || _self.presentedViewController != nil {
                _self.reloadSwipableView()
            }
        }
        
        setupView()
        setupSwipeableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !firstLoadHappened {
            firstLoadHappened = true
            reloadSwipableView()
            
            UIView.animate(withDuration: 0.3) {
                self.swipeableView.alpha = 1
            }
        }
    }
    
    // MARK:- Actions
    @IBAction func gotToPreviousCard(_ sender: Any) {
        previousCard()
    }
    
    @IBAction func shuffle(_ sender: Any) {
        shuffleCards()
    }
    
    // MARK:- Other funcs
    private func setupSwipeableView() {
        
        swipeableView.allowedDirection = [.Up, .Horizontal]
        swipeableView.onlySwipeTopCard = true
        
        swipeableView.nextView = { [weak self] in
            guard let _self = self else { return nil }
            
            if _self.dataSource.count == 0 {
                return nil
            }
            
            if _self.nextCardIndex >= _self.dataSource.count {
                return nil
            }
            
            let card = _self.dataSource[_self.nextCardIndex]
            
            // Setup `CardView`
            let frame = CGRect(origin: .zero, size: CardUI.cardSizeFor(view: _self.view))
            let cardView = CardView(frame: frame)
            cardView.cardId = card.id
            cardView.frontText = card.frontText
            cardView.backText = card.backText
            cardView.frontImage = card.frontImage
            cardView.backImage = card.backImage
            
            // Set action on edit card button
            cardView.editCardButton.addTarget(_self, action: #selector(_self.showCardEditor), for: .touchUpInside)
            
            // Advance `cardIndex`
            _self.nextCardIndex += 1
            
            return cardView
        }
        
        swipeableView.didSwipe = { [weak self] view, direction, _ in
            guard let _self = self else { return }
            
            _self.didSwipe = true
            
            if direction == .Up {
                guard let cardView = view as? CardView, let cardId = cardView.cardId else { return }
                
                let realm = try! Realm()
                let card = realm.object(ofType: Card.self, forPrimaryKey: cardId)
                
                let date = Date()
                try? realm.write {
                    card?.mastered = date
                    card?.modified = date
                    if self?.stack.preferences == nil {
                        let prefs = StackPreferences(stack: _self.stack)
                        realm.add(prefs, update: true)
                        self?.stack.preferences = prefs
                    }
                    self?.stack.preferences?.modified = date
                }
                
                if #available(iOS 10.0, *) {
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(UINotificationFeedbackType.success)
                }
                
                _self.nextCardIndex -= 1
            }
            
            if #available(iOS 10.0, *) {
                let feedback = UIImpactFeedbackGenerator(style: .light)
                feedback.impactOccurred()
            }
            
            if _self.nextCardIndex >= _self.dataSource.count && _self.swipeableView.topView() == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    _self.reloadSwipableView()
                }
            }
            
            _self.previousButton.isEnabled = _self.swipeableView.history.count > 0
            _self.shuffleButton.isEnabled = _self.dataSource.count > 0

            // Hide helper views
            _self.hideHelpers()
            _self.updateStackStatusLabel()
        }
        
        swipeableView.swiping = { [weak self] _, _, location in
            guard let _self = self else { return }
            
            if location.y+50 > 0 {
                self?.hideHelpers()
                return
            }
            
            let y = abs(location.y+50)
            
            let yAlpha = y/100
            
            _self.masteredHelperView.alpha = yAlpha
        }
        
        swipeableView.didStart = { _, _ in
            if #available(iOS 10.0, *) {
                let feedback = UISelectionFeedbackGenerator()
                feedback.selectionChanged()
            }
        }
        
        swipeableView.didCancel = { [weak self] _ in
            self?.hideHelpers()
        }
    }
    
    private func reloadSwipableView() {
        nextCardIndex = 0
        previousButton.isEnabled = false
        shuffleButton.isEnabled = dataSource.count > 0
        swipeableView.numberOfActiveView = dataSource.count >= 4 ? 4 : UInt(dataSource.count)
        swipeableView.discardViews()
        swipeableView.loadViews()
        updateStackStatusLabel()
    }

    private func updateStackStatusLabel() {
        stacksStatusImageView.isHidden = true
        stackStatusLabel.text = ""
        
        if dataSource.count == 0 {
            stacksStatusImageView.isHidden = false
            stackStatusLabel.text = MasteredCardsMessage
            if didSwipe {
                ReviewController.showReviewAlert()
            }
        }
        
        if stack.cards.count == 0 {
            stacksStatusImageView.isHidden = true
            stackStatusLabel.text = NoCardsMessage
        }
    }
    
    private func hideHelpers() {
        UIView.animate(withDuration: 0.3) {
            self.masteredHelperView.alpha = 0
        }
    }
    
    private func setupView() {
        if stack.isInvalidated {
            let _ = navigationController?.popToRootViewController(animated: true)
        } else {
            title = stack.name
            stackDetailsLabel.text = stack.progressDescription
            progressBar.setProgress(CGFloat(stack.masteredCards.count), of: CGFloat(stack.sortedCards.count))
        }
    }
    
    private func previousCard() {
        swipeableView.rewind()
        previousButton.isEnabled = false
    }
    
    func showCardEditor(sender: UIButton) {
        
        guard let cardView = sender.superview?.superview?.superview as? CardView, let cardId = cardView.cardId else { return }
        performSegue(withIdentifier: "showCardEditor", sender: cardId)
    }
    
    private func shuffleCards() {
        
        if #available(iOS 10.0, *) {
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.warning)
        }
        
        let unmasteredCards = Array(stack.unmasteredCards)
        
        let shuffledCards: [Card] = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: unmasteredCards) as! [Card]
        
        let realm = try! Realm()
        
        try? realm.write {
            shuffledCards.enumerated().forEach { index, card in
                card.order = Float(index)
                card.modified = Date()
                stack.preferences?.modified = Date()
            }
        }
        
        reloadSwipableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch (segue.destination, sender) {
        case (let vc as StackViewController, _):
            vc.stack = stack
            vc.editMode = true
        case (let vc as FlashCardViewController, let cardId as String):
            let realm = try! Realm()
            let card = realm.object(ofType: Card.self, forPrimaryKey: cardId)
            vc.stack = stack
            vc.card = card
        default: break
        }
    }
    
    /// Handle updating sizes for subviews when changing orientation/size
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { context in
            self.swipeableView.alpha = 0
        }) { (context) in
            let views = self.swipeableView.activeViews().flatMap { $0 as? CardView }
            let cardSize = CardUI.cardSizeFor(view: self.view)
            views.forEach { view in
                view.frame.size.width = cardSize.width
                view.frame.size.height = cardSize.height
                view.widthConstraint.constant = cardSize.width
                view.heightConstraint.constant = cardSize.height
            }
            self.swipeableView.loadViews()
            self.swipeableView.alpha = 1
        }
    }
    
    // MARK: - Shake handler
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        
        switch motion {
        case .motionShake:
            shuffleCards()
        default:
            break
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
