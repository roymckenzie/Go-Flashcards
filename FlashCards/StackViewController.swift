//
//  StackViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/7/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift

class StackViewController: UIViewController, RealmNotifiable {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var stackTitleLabel: UILabel!
    @IBOutlet weak var stackDetailsLabel: UILabel!
    
    var stack:    Stack!
    var editMode:   Bool = false
    
    var realmNotificationToken: NotificationToken?
    
    lazy var collectionController: CardsCollectionViewController = {
        return CardsCollectionViewController(collectionView: self.collectionView, stack: self.stack)
    }()
    
    deinit {
        stopRealmNotification()
        NSLog("[StackViewController] deinit")
    }
    
    override var title: String? {
        didSet {
            stackTitleLabel.text = title
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        startRealmNotification() { [weak self] _ in
            guard let _self = self else { return }
            if _self.stack.isInvalidated || _self.stack.cards.isInvalidated {
                let _ = _self.navigationController?.popToRootViewController(animated: true)
                return
            }
            _self.title = _self.stack.name
            _self.stackDetailsLabel.text = _self.stack.progressDescription
            _self.collectionView?.reloadData()
        }
        
        if editMode {
            title = stack.name
            stackDetailsLabel.text = stack.progressDescription
        } else {
            let realm = try? Realm()
            stack = Stack()
            
            try? realm?.write {
                realm?.add(stack)
            }
        }
        
        collectionController.didSelectItem = { [weak self] card, indexPath in
            self?.performSegue(withIdentifier: "editCardSegue", sender: card)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.destination {
        case let vc as FlashCardViewController:
            if let card = sender as? Card {
                vc.card = card
            }
            vc.stack = stack
        case let vc as EditStackViewController:
            vc.stack = stack
        default: break
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        collectionView.reloadData()
    }
}

// MARK:- UITextFieldDelegate
extension StackViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
