//
//  StacksCollectionViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/24/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift

private let AddYourFirstStack = NSLocalizedString("Add your\nfirst Stack", comment: "Helper text for blank stack cell")

final class StacksCollectionViewController: NSObject {
    
    private weak var collectionView: UICollectionView!
    
    let realm = try! Realm()
    var realmNotificationToken: NotificationToken?
    
    var dataSource: Results<Stack> {
        let undeletedPredicate = NSPredicate(format: "deleted == nil")
        guard let query = query else {
            return realm.objects(Stack.self).filter(undeletedPredicate).sorted(byKeyPath: "name")
        }
        let predicate = NSPredicate(format: "name CONTAINS[c] %@", query)
        return realm.objects(Stack.self).filter(undeletedPredicate).filter(predicate)
    }
    
    fileprivate var query: String? {
        didSet {
            collectionView.alwaysBounceVertical = query == nil
        }
    }
    
    var didSelectItem: ((Stack, IndexPath) -> Void)?
    var createNewItem: (()-> Void)?
    
    func performSearch(query: String?) {
        self.query = query
        collectionView.reloadData()
    }
    
    func startRealmNotification() {
        do {
            let realm = try Realm()
            realmNotificationToken = realm.addNotificationBlock() { [weak self] _, _ in
                self?.collectionView?.reloadData()
            }
        } catch {
            NSLog("Error setting up Realm Notification: \(error)")
        }
    }
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        
        startRealmNotification()
        
        collectionView.registerNib(StackCell.self)
        collectionView.registerNib(BlankCardCell.self)
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    deinit {
        NSLog("[StacksCollectionViewController] denit")
        realmNotificationToken?.stop()
    }
}

private let StackSpacing: CGFloat = 15
extension StacksCollectionViewController: UICollectionViewDelegateFlowLayout {
    
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
            cell.fakeCardCount = stack.sortedCards.count
            cell.nameLabel?.text = stack.name
            cell.cardCountLabel.text = stack.progressDescription
            cell.sharedImageView.isHidden = !stack.isSharedWithMe
            cell.progressBar.isHidden = stack.cards.isEmpty
            cell.progressBar.setProgress(CGFloat(stack.masteredCards.count),
                                         of: CGFloat(stack.sortedCards.count),
                                         animated: false)
        case let cell as BlankCardCell:
            cell.textLabel.text = AddYourFirstStack
        default: break
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if dataSource.isEmpty && query == nil {
            createNewItem?()
            return
        }
        let stack = dataSource[indexPath.item]
        didSelectItem?(stack, indexPath)
    }
}

extension StacksCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if dataSource.isEmpty && query == nil {
            return 1
        }
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if dataSource.isEmpty && query == nil {
            return collectionView.dequeueReusableCell(withClass: BlankCardCell.self, for: indexPath)
        }
        return collectionView.dequeueReusableCell(withClass: StackCell.self, for: indexPath)
    }
}

