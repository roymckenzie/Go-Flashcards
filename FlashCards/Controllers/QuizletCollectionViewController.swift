//
//  QuizletCollectionViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/28/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

final class QuizletCardsCollectionViewController: NSObject {
    
    weak var collectionView: UICollectionView!
    
    var dataSource = [QuizletCard]() {
        didSet { collectionView.reloadData() }
    }
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        
        collectionView.registerNib(CardCell.self)
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

private let CardSpacing: CGFloat = 15
extension QuizletCardsCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let rowCount: CGFloat
        
        // width, height
        switch (collectionView.traitCollection.horizontalSizeClass, collectionView.traitCollection.verticalSizeClass) {
        case (.regular, .regular):
            rowCount = 5
        case (.compact, .regular):
            rowCount = 3
        case (.compact, .compact):
            rowCount = 5
        default:
            rowCount = 1
        }
        
        let totalVerticalSpacing = ((rowCount-1)*CardSpacing) + (CardSpacing*2)
        let verticalSpacingAffordance = totalVerticalSpacing / rowCount
        let width = (collectionView.frame.size.width / rowCount) - verticalSpacingAffordance
        let height = width * 1.333
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return CardSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CardSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch section {
        case 0:
            return UIEdgeInsets(top: CardSpacing, left: CardSpacing, bottom: CardSpacing, right: CardSpacing)
        default:
            return UIEdgeInsets(top: 0, left: CardSpacing, bottom: CardSpacing, right: CardSpacing)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        setCellContentsFor(indexPath: indexPath, cell: cell)
    }
    
    func setCellContentsFor(indexPath: IndexPath, cell: UICollectionViewCell) {
        let cell = cell as? CardCell
        let card = dataSource[indexPath.row]
        cell?.frontText = card.frontText
        if let backImageUrl = card.backImageUrl {
            cell?.setImageWith(url: backImageUrl)
        }
    }
}

extension QuizletCardsCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withClass: CardCell.self, for: indexPath)
    }
}
