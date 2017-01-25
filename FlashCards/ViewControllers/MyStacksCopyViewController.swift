//
//  MyStacksCopyViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/24/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

final class MyStacksCopyViewController: StatusBarHiddenAnimatedViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    lazy var stackController: StacksCollectionViewController = {
        return StacksCollectionViewController(collectionView: self.collectionView)
    }()
    
    var didSelectItem: ((Stack, IndexPath) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stackController.didSelectItem = { [weak self] stack, indexPath in
            self?.didSelectItem?(stack, indexPath)
        }
    }
    
    @IBAction func cancel() {
        dismiss(animated: true, completion: nil)
    }
}


