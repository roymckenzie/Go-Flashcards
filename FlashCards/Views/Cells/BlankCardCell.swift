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
    
    var dashedLayer: CAShapeLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        dashedLayer = CAShapeLayer()
        dashedLayer?.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        dashedLayer?.fillColor = nil
        dashedLayer?.lineDashPattern = [10,5]
        dashedLayer?.lineWidth = 4
        layer.addSublayer(dashedLayer!)
        layer.cornerRadius = 8
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dashedLayer?.path = UIBezierPath(roundedRect: bounds, cornerRadius: 8).cgPath
        dashedLayer?.frame = bounds
    }
}
