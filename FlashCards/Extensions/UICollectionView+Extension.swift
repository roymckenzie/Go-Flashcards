//
//  UICollectionView+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/28/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func registerNib(_ cellClass: Swift.AnyClass) {
        let nib = UINib(nibName: "\(cellClass)", bundle: nil)
        register(nib, forCellWithReuseIdentifier: "\(cellClass)")
    }
    
    func registerSupplementaryViewNib(forKind kind: String, viewClass: Swift.AnyClass) {
        let nib = UINib(nibName: "\(viewClass)", bundle: nil)
        register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: "\(viewClass)")
    }
    
    func register(_ cellClass: Swift.AnyClass) {
        register(cellClass, forCellWithReuseIdentifier: "\(cellClass)")
    }
    
    func dequeueReusableCell<T: UICollectionViewCell>(withClass cellClass: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withReuseIdentifier: "\(cellClass)", for: indexPath) as! T
    }
    
    func dequeueReusableSupplementaryView<T: UICollectionReusableView>(ofKind kind: String, withClass viewClass: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "\(viewClass)", for: indexPath) as! T
    }
}
