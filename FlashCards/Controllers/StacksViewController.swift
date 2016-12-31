//
//  StacksViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/25/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift

class StacksViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    lazy var stacksCollectionController: StacksCollectionViewController = {
        return StacksCollectionViewController(collectionView: self.collectionView)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stacksCollectionController.didSelectItem = { [weak self] stack, indexPath in
            self?.performSegue(withIdentifier: "showCards", sender: stack)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? FlashCardsViewController,
                    let stack = sender as? Stack {
            
            viewController.stack = stack
        }
    }
}

final class StacksCollectionViewController: NSObject {
    
    weak var collectionView: UICollectionView?
    
    let realm = try! Realm()
    var realmNotificationToken: NotificationToken?
    
    var dataSource: Results<Stack> {
        get {
            return realm.objects(Stack.self)
        }
    }
    
    var didSelectItem: ((Stack, IndexPath) -> ())?
    
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
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    deinit {
        NSLog("StacksCollectionViewController denit")
        realmNotificationToken?.stop()
    }
}

private let StackSpacing: CGFloat = 15
extension StacksCollectionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let rowCount: CGFloat
        switch collectionView.traitCollection.horizontalSizeClass {
        case .regular:
            rowCount = 4
        case .compact:
            rowCount = 2
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
        return UIEdgeInsets(top: StackSpacing, left: StackSpacing, bottom: 0, right: StackSpacing)

    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let cell = cell as? StackCell else { return }
        let stack = dataSource[indexPath.item]
        cell.fakeCardCount = stack.sortedCards.count
        cell.nameLabel?.text = stack.name
        cell.cardCountLabel.text = stack.cardCountString
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let stack = dataSource[indexPath.item]
        didSelectItem?(stack, indexPath)
    }
}

extension StacksCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withClass: StackCell.self, for: indexPath)
    }
}
