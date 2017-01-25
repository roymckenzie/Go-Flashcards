//
//  QuizletStacksCollectionViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/24/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

final class QuizletStacksCollectionViewController: NSObject {
    
    private weak var collectionView: UICollectionView!
    
    var dataSource = [QuizletStack]() {
        didSet { reloadData() }
    }
    
    var didSelectItem: ((QuizletStack, IndexPath) -> ())?
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        
        collectionView.registerNib(StackCell.self)
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func reloadData() {
        collectionView.backgroundColor = dataSource.isEmpty ? .clear : .black
        collectionView.reloadData()
        collectionView.contentOffset.y = 0
    }
    
    deinit {
        NSLog("[QuizletStacksCollectionViewController] denit")
    }
}

private let StackSpacing: CGFloat = 15
extension QuizletStacksCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let rowCount: CGFloat
        
        // width, height
        switch (collectionView.traitCollection.horizontalSizeClass, collectionView.traitCollection.verticalSizeClass) {
        case (.regular, .regular):
            rowCount = 4
        case (.compact, .regular):
            rowCount = 2
        case (.compact, .compact):
            rowCount = 4
        default:
            rowCount = 1
        }
        
        let totalVerticalSpacing = ((rowCount-1)*StackSpacing) + (StackSpacing*2)
        let verticalSpacingAffordance = totalVerticalSpacing / rowCount
        let width = (collectionView.frame.size.width / rowCount) - verticalSpacingAffordance
        let height = width * 1.333
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return StackSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return StackSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: StackSpacing, left: StackSpacing, bottom: StackSpacing, right: StackSpacing)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        switch cell {
        case let cell as StackCell:
            let stack = dataSource[indexPath.item]
            cell.fakeCardCount = stack.cardCount
            cell.nameLabel?.text = stack.name
            cell.cardCountLabel.text = "\(stack.cardCount) cards"
            cell.sharedImageView.isHidden = true
            cell.progressBar.isHidden = true
            //            cell.progressBar.setProgress(CGFloat(stack.masteredCards.count),
            //                                         of: CGFloat(stack.sortedCards.count),
        //                                         animated: false)
        default: break
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let stack = dataSource[indexPath.item]
        didSelectItem?(stack, indexPath)
    }
}

extension QuizletStacksCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withClass: StackCell.self, for: indexPath)
    }
}
