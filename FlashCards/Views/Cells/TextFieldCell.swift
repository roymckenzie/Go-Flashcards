//
//  TextFieldCell.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/8/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

final class TextFieldCell: UITableViewCell {

    @IBOutlet weak var textField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
