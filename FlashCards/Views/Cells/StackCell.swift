//
//  StackCell.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/25/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

class StackCell: UICollectionViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cardCountLabel: UILabel!
    
    @IBOutlet weak var fakeCardOne: UIView!
    @IBOutlet weak var fakeCardTwo: UIView!
    @IBOutlet weak var fakeCardThree: UIView!
    
    @IBOutlet weak var noCardView: UIView!
    
    @IBOutlet weak var progressBar: ProgressBar!
    
    // For subscripting
    var fakeCards: [UIView] {
        return [fakeCardOne, fakeCardTwo, fakeCardThree]
    }
    
    var fakeCardCount = 0 {
        didSet {
            if fakeCardCount == 0 {
                noCardView.isHidden = false
                fakeCards.forEach({ $0.isHidden = true })
                return
            }
            fakeCards.enumerated().forEach { offset, view in
                view.isHidden = offset >= fakeCardCount
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        noCardView.layer.cornerRadius = 8
        
        var degrees: Double = -(drand48()*3)
        fakeCards.forEach {
            $0.layer.cornerRadius = 8
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOpacity = 0.3
            $0.transform = CGAffineTransform(rotationAngle: CGFloat(degrees * M_PI)/CGFloat(180))
            $0.layer.rasterizationScale = 2
            $0.layer.shouldRasterize = true
            degrees *= -(drand48()*3)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        noCardView.isHidden = true
    }
}
