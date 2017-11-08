//
//  UIToolbar+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/6/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

private let Done = NSLocalizedString("Done", comment: "Done buttons")
extension UIToolbar {
    
    static var doneInputAccessoryView: DoneKeyboardToolbar {
        let toolbar = DoneKeyboardToolbar()
        toolbar.barTintColor = .black
        toolbar.frame.size.height = 44
        toolbar.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        
        let doneButton = UIBarButtonItem(title: Done, style: .done, target: nil, action: nil)
        doneButton.tintColor = .lightGray
        doneButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.regular)], for: .normal)
        
        let flexWidthButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbar.setItems([flexWidthButton, doneButton], animated: true)
        
        return toolbar
    }
}

final class DoneKeyboardToolbar: UIToolbar {
    
    weak var doneButton: UIBarButtonItem!
    
    override func setItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        super.setItems(items, animated: animated)
        
        guard let items = items else { return }
        doneButton = items[1]
    }
}
