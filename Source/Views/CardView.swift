//
//  CardView.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/27/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit
import ZLSwipeableViewSwift

class CardView: UIView, ViewNibNestable {
    
    var reusableViewLayoutConstraints: (NSLayoutConstraint, NSLayoutConstraint, NSLayoutConstraint, NSLayoutConstraint)?
    
    var heightConstraint: NSLayoutConstraint {
        return reusableViewLayoutConstraints!.2
    }
    
    var widthConstraint: NSLayoutConstraint {
        return reusableViewLayoutConstraints!.3
    }
    
    @IBOutlet weak var editCardButton: UIButton!
    
    @IBOutlet weak var frontLabelViewArea: UIView!
    @IBOutlet weak var backLabelViewArea: UIView!
    
    @IBOutlet weak var frontView: UIView!
    @IBOutlet private weak var frontTextLabel: UILabel!
    @IBOutlet private weak var frontImageView: UIImageView!
    @IBOutlet weak var frontImageViewContentModeButton: UIButton!
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet private weak var backTextLabel: UILabel!
    @IBOutlet private weak var backImageView: UIImageView!
    @IBOutlet weak var backImageViewContentModeButton: UIButton!

    private let tapGesture = UITapGestureRecognizer()
    
    var frontImage: UIImage? {
        didSet {
            frontImageView.image = frontImage
            layoutViews()
        }
    }
    var backImage: UIImage? {
        didSet {
            backImageView.image = backImage
            layoutViews()
        }
    }
    
    var frontText: String? {
        didSet {
            frontTextLabel.text = frontText
            layoutViews()
        }
    }
    var backText: String? {
        didSet {
            backTextLabel.text = backText
            layoutViews()
        }
    }
    
    var insertedSubview: UIView!
    
    // Storage for specific card since ZLSwipeable doesn't support
    // data indexing like CollectionView objects
    var cardId: String!
    
    private var currentSide = CardSide.front
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        insertedSubview = reuseView(withSize: frame.size)
        setup()
    }
    
    private func setup() {
        // Shadow
        insertedSubview.layer.shadowColor = UIColor.black.cgColor
        insertedSubview.layer.shadowOpacity = 0.45
        insertedSubview.layer.shadowOffset = CGSize(width: 0, height: 1.5)
        insertedSubview.layer.shadowRadius = 4.0
        insertedSubview.layer.shouldRasterize = true
        insertedSubview.layer.rasterizationScale = UIScreen.main.scale
        
        // Corner Radius
        insertedSubview.layer.cornerRadius = 10.0
        frontView?.layer.cornerRadius = 10.0
        backView?.layer.cornerRadius = 10.0
        
        insertedSubview.addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(toggleSide))
    }
    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func toggleSide() {
        
        if #available(iOS 10.0, *) {
            let feedback = UISelectionFeedbackGenerator()
            feedback.selectionChanged()
        }
        
        let fromView    = currentSide == .front ? frontView : backView
        let toView      = currentSide == .front ? backView : frontView
        
        guard let _toView = toView, let _fromView = fromView else { return }
        insertedSubview.layer.shouldRasterize = false
        insertedSubview.layer.shadowOpacity = 0
        UIView.transition(from: _fromView,
                          to: _toView,
                          duration: 0.6,
                          options: [.showHideTransitionViews,
                                    currentSide.transitionDirectionAnimationOption,
                                    .allowAnimatedContent]) { _ in
            
            self.currentSide = self.currentSide.nextSide
            self.insertedSubview.layer.shouldRasterize = true
            self.insertedSubview.layer.shadowOpacity = 0.45
        }


    }
    
    @IBAction func toggleBackImageSize(_ button: UIButton) {
        toggleImageViewMode(imageView: backImageView, button: button)
    }
    
    @IBAction func toggleFrontImageSize(_ button: UIButton) {
        toggleImageViewMode(imageView: frontImageView, button: button)
    }
    
    func toggleImageViewMode(imageView: UIImageView, button: UIButton) {
        
        UIView.animate(withDuration: 0.2) {
            let selected = button.isSelected
            button.isSelected = !selected
            
            if selected {
                imageView.contentMode = .scaleAspectFill
            } else {
                imageView.contentMode = .scaleAspectFit
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setup()
        layoutViews()
    }
    
    func layoutViews() {
        frontImageViewContentModeButton.isHidden = true
        backImageViewContentModeButton.isHidden = true
        frontImageView.isHidden = true
        backImageView.isHidden = true
        frontTextLabel.isHidden = true
        backTextLabel.isHidden = true
        frontLabelViewArea.isHidden = true
        backLabelViewArea.isHidden = true
        
        if let _ = frontImage {
            frontImageView.isHidden = false
            frontImageViewContentModeButton.isHidden = false
        }
        
        if let _ = backImage {
            backImageView.isHidden = false
            backImageViewContentModeButton.isHidden = false
        }
        
        if let frontText = frontText, !frontText.isEmpty {
            frontTextLabel.isHidden = false
            frontLabelViewArea.isHidden = false
        }
        
        if let backText = backText, !backText.isEmpty {
            backTextLabel.isHidden = false
            backLabelViewArea.isHidden = false
            backTextLabel.sizeToFit()
        }
    }
}

// Hashable override
extension CardView {
    
    override var hashValue: Int {
        return cardId.hashValue
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? CardView else {
            return false
        }
        return object.cardId == cardId
    }
}
