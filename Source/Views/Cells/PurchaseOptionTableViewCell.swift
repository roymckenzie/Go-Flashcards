//
//  PurchaseOptionTableViewCell.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/27/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

private let RegularFont = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.regular)
private let SemiboldFont = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold)
class PurchaseOptionTableViewCell: UITableViewCell {

    @IBOutlet weak var selectImageView: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var productTitleLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        priceLabel.font = RegularFont
        productTitleLabel.font = RegularFont
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        priceLabel.font = selected ? SemiboldFont : RegularFont
        productTitleLabel.font = selected ? SemiboldFont : RegularFont
        selectImageView.isHidden = !selected
    }
    
}
