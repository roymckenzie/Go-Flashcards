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
    @IBOutlet weak var editCardButton: UIButton!
    
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var frontTextLabel: UILabel!
    @IBOutlet weak var frontImageView: UIImageView!
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var backTextLabel: UILabel!
    @IBOutlet weak var backImageView: UIImageView!
    
    private let tapGesture = UITapGestureRecognizer()
    
    private var insertedSubview: UIView!
    
    // Storage for specific card since ZLSwipeable doesn't support
    // data indexing like CollectionView objects
    var cardId: String?
    
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
        
        let fromView    = currentSide == .front ? frontView : backView
        let toView      = currentSide == .front ? backView : frontView
        
        guard let _toView = toView, let _fromView = fromView else { return }

        UIView.transition(from: _fromView,
                          to: _toView,
                          duration: 0.6,
                          options: [.showHideTransitionViews]) { _ in
                            
            self.currentSide = self.currentSide.nextSide
        }
    }    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setup()
    }
}
