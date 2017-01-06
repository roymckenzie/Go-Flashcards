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
    
    @IBOutlet weak var frontView: UIView!
    @IBOutlet private weak var frontTextLabel: UILabel!
    @IBOutlet private weak var frontImageView: UIImageView!
    @IBOutlet weak var frontImageViewContentModeButton: UIButton!
    @IBOutlet weak var frontImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var frontTextLabelYConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet private weak var backTextLabel: UILabel!
    @IBOutlet private weak var backImageView: UIImageView!
    @IBOutlet weak var backImageViewContentModeButton: UIButton!
    @IBOutlet weak var backImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var backTextLabelYConstraint: NSLayoutConstraint!

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
    
    func toggleSide() {
        
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
        
        if let _ = frontImage {
            frontImageViewContentModeButton.isHidden = false
        }
        
        if let _ = backImage {
            backImageViewContentModeButton.isHidden = false
        }
        
        let imageConstraintConstant = insertedSubview.frame.height / 2
        let textLabelConstraintConstant = insertedSubview.frame.height / 4

        
        if let _ = backImage, let backText = backText, backText.characters.count > 0 {
            backImageViewTopConstraint.constant = imageConstraintConstant
            backTextLabelYConstraint.constant = -textLabelConstraintConstant
        }
        
        if let _ = frontImage, let frontText = frontText, frontText.characters.count > 0 {
            frontImageViewTopConstraint.constant = imageConstraintConstant
            frontTextLabelYConstraint.constant = -textLabelConstraintConstant
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

final class NewCardView: UIView {
    private let frontView = UIView()
    private let backView = UIView()
    
    let frontTextLabel = UILabel()
    let backTextLabel = UILabel()
    
    let frontImageView = UIImageView()
    let backImageView = UIImageView()
    
    private let frontTapGesture = UITapGestureRecognizer()
    private let backTapGesture = UITapGestureRecognizer()
    
    let editButton = UIButton()
    
    var cardId: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews()
        addSubviewConstraints()
        roundCorners()
        styleViews()
        setupTapGesture()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var currentSide = CardSide.front
    
    private func addSubviews() {
        
        addSubview(backView)
        addSubview(frontView)
        
        frontView.addSubview(frontImageView)
        frontView.addSubview(frontTextLabel)

        backView.addSubview(backImageView)
        backView.addSubview(backTextLabel)
        backView.addSubview(editButton)
    }
    
    private func addSubviewConstraints() {

        backView.translatesAutoresizingMaskIntoConstraints = false
        frontView.translatesAutoresizingMaskIntoConstraints = false
        frontTextLabel.translatesAutoresizingMaskIntoConstraints = false
        backTextLabel.translatesAutoresizingMaskIntoConstraints = false
        frontImageView.translatesAutoresizingMaskIntoConstraints = false
        backImageView.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        
        backView.boundInside(superview: self)
        frontView.boundInside(superview: self)
        
        frontImageView.boundInside(superview: frontView)
        backImageView.boundInside(superview: backView)
        
        frontTextLabel.widthAnchor.constraint(equalTo: widthAnchor, constant: -20).isActive = true
        backTextLabel.widthAnchor.constraint(equalTo: widthAnchor, constant: -20).isActive = true

        frontTextLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        frontTextLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        backTextLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        backTextLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        editButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -20).isActive = true
        editButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20).isActive = true
    }
    
    private func roundCorners() {
//        backView.round(corners: [.allCorners], radius: 8)
//        frontView.round(corners: [.allCorners], radius: 8)
    }
    
    private func styleViews() {
        frontView.backgroundColor = .white
        backView.backgroundColor = .lightGray
        
        frontView.layer.cornerRadius = 8
        backView.layer.cornerRadius = 8
        
        frontView.clipsToBounds = true
        backView.clipsToBounds = true
        
        frontTextLabel.numberOfLines = 0
        backTextLabel.numberOfLines = 0
        
        frontTextLabel.textAlignment = .center
        backTextLabel.textAlignment = .center
        
        editButton.setImage(#imageLiteral(resourceName: "icon-edit"), for: .normal)
            
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.cornerRadius = 8
    }
    
    private func setupTapGesture() {
        backView.addGestureRecognizer(backTapGesture)
        frontView.addGestureRecognizer(frontTapGesture)
        frontTapGesture.addTarget(self, action: #selector(toggleSide))
        backTapGesture.addTarget(self, action: #selector(toggleSide))
    }
    
    func toggleSide() {
        
        let fromView    = currentSide == .front ? frontView : backView
        let toView      = currentSide == .front ? backView : frontView
        
        layer.shouldRasterize = false
        UIView.transition(from: fromView,
                          to: toView,
                          duration: 0.6,
                          options: [.showHideTransitionViews,
                                    currentSide.transitionDirectionAnimationOption,
                                    .allowAnimatedContent]) { _ in
                                        
                                        self.currentSide = self.currentSide.nextSide
                                        self.layer.shouldRasterize = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.rasterizationScale = 2
        layer.shouldRasterize = true

    }
}
