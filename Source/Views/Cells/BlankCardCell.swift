//
//  BlankCardCell.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/28/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

class BlankCardCell: UICollectionViewCell {

    @IBOutlet weak var textLabel: UILabel!
    
    lazy var dashedLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        layer.fillColor = nil
        layer.lineDashPattern = [10,5]
        layer.lineWidth = 4
        self.layer.addSublayer(layer)
        return layer
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = 8
        dashedLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 8).cgPath
        dashedLayer.frame = bounds
    }
}
