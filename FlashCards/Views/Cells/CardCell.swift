//
//  CardCell.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/28/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

class CardCell: UICollectionViewCell {

    @IBOutlet weak var frontTextLabel: UILabel!
    @IBOutlet weak var frontImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        layer.cornerRadius = 8
    }
}
