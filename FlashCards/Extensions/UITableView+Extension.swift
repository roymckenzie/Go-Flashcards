//
//  UITableView+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/8/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

extension UITableView {
    
    func register(nibWithClass className: Swift.AnyClass) {
        let nib = UINib(nibName: "\(className)", bundle: nil)
        register(nib, forCellReuseIdentifier: "\(className)")
    }
    
    func dequeueCell<T: UITableViewCell>(withNibClass className: T.Type, indexPath: IndexPath) -> T {
        return dequeueReusableCell(withIdentifier: "\(className)", for: indexPath) as! T
    }
}
