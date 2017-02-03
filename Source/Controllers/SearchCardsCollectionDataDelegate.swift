//
//  SearchCardsCollectionDataDelegate.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/24/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift

final class SearchCardsCollectionDataDelegate: NSObject {
    
    let realm = try! Realm()
    
    var dataSource: Results<Card> {
        guard let query = query else {
            return realm.objects(Card.self)
        }
        let predicate = NSPredicate(format: "frontText CONTAINS[c] %@ OR backText CONTAINS[c] %@", query, query)
        return realm.objects(Card.self).filter(predicate)
    }
    
    private var query: String?
    
    var didSelectItem: ((Card, IndexPath) -> Void)?
    
    func performSearch(query: String?) {
        self.query = query
    }
    
    init(collectionView: UICollectionView) {
        super.init()
        
        collectionView.registerNib(CardCell.self)
    }
}

private let CardSpacing: CGFloat = 15
extension SearchCardsCollectionDataDelegate: UICollectionViewDelegateFlowLayout {
    
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
        return UIEdgeInsets(top: CardSpacing, left: CardSpacing, bottom: CardSpacing, right: CardSpacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        setCellContentsFor(indexPath: indexPath, cell: cell)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let card = cardFor(indexPath)
        didSelectItem?(card, indexPath)
    }
    
    func setCellContentsFor(indexPath: IndexPath, cell: UICollectionViewCell) {
        let cell = cell as? CardCell
        cell?.frontImage = cardImageFor(indexPath)
        cell?.frontText = cardTextFor(indexPath)
    }
    
    func cardFor(_ indexPath: IndexPath) -> Card {
        return dataSource[indexPath.item]
    }
    
    func cardTextFor(_ indexPath: IndexPath) -> String? {
        return dataSource[indexPath.item].frontText
    }
    
    func cardImageFor(_ indexPath: IndexPath) -> UIImage? {
        return dataSource[indexPath.item].frontImage
    }
}

extension SearchCardsCollectionDataDelegate: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withClass: CardCell.self, for: indexPath)
    }
}

