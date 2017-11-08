//
//  StacksViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/25/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift

private let Syncing = NSLocalizedString("Syncing", comment: "Refresh control syncing")

final class MyStacksViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    
    lazy var stacksCollectionController: StacksCollectionViewController = {
        return StacksCollectionViewController(collectionView: self.collectionView)
    }()
    
    lazy var cardsCollectionController: SearchCardsCollectionDataDelegate = {
        return SearchCardsCollectionDataDelegate(collectionView: self.collectionView)
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let attributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(startSync), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: Syncing, attributes: attributes)
        return refreshControl
    }()
    
    // MARK:- Override supers
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSearchBar()
        setupCollectionViewControllers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        addKeyboardListeners() { [weak self] height in
            var height = height
            if height > 0 {
                height -= (self?.tabBarController?.tabBar.frame.height ?? 0)
            }
            self?.collectionViewBottomConstraint.constant = height
            
            UIView.animate(withDuration: 0.3) {
                self?.view.layoutIfNeeded()
            }
        }
        collectionViewBottomConstraint.constant = 0
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        removeKeyboardListeners()
    }
    
    deinit {
        NSLog("[MyStacksViewController] deinit")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.destination {
        case let vc as FlashCardsViewController:
            vc.stack = sender as? Stack
        case let vc as FlashCardViewController:
            vc.card = sender as? Card
        default: break
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        collectionView.reloadData()
    }
    
    // MARK:- Actions
    @IBAction func toggleSearch(_ sender: Any) {
        toggleSearchVisibility()
    }
    
    private func setupCollectionViewControllers() {
        
        stacksCollectionController.didSelectItem = { [weak self] stack, indexPath in
            self?.performSegue(withIdentifier: "showCards", sender: stack)
        }
        
        cardsCollectionController.didSelectItem = { [weak self] card, _ in
            let vc = Storyboard.main.instantiateViewController(FlashCardViewController.self) { vc in
                vc.card = card
            }
            self?.tabBarController?.present(vc, animated: true, completion: nil)
        }
        
        stacksCollectionController.createNewItem = { [weak self] in
            self?.performSegue(withIdentifier: "newStack", sender: nil)
        }
        
        collectionView.addSubview(refreshControl)
    }
    
    @objc func startSync(_ refreshControl: UIRefreshControl) {
        refreshControl.beginRefreshing()
        CloudKitSyncManager.current
            .runSync()
            .always {
                refreshControl.endRefreshing()
            }
            .catch { error in
                NSLog("Couldn't manually refresh: \(error)")
            }
    }
    
    private func setupSearchBar() {
        
        searchBar.keyboardAppearance = .dark
        toggleSearchVisibility()
    }
    
    fileprivate func toggleSearchVisibility() {
        
        let barIsHidden = searchBar.alpha == 0
        
        searchBarTopConstraint.constant = barIsHidden ? 0 : -44
        
        UIView.animate(withDuration: 0.3) {
            self.searchBar.alpha = barIsHidden ? 1 : 0
            self.view.layoutIfNeeded()
        }
        
        if barIsHidden {
            searchBar.showsScopeBar = true
            searchBar.showsCancelButton = true
            searchBar.becomeFirstResponder()
        } else {
            view.endEditing(true)
            searchBar.showsScopeBar = false
            searchBar.showsCancelButton = false
            searchBar.selectedScopeButtonIndex = 0
            stacksCollectionController.performSearch(query: nil)
            collectionView.delegate = stacksCollectionController
            collectionView.dataSource = stacksCollectionController
        }
    }
}

// MARK:- KeyboardAvoidable
extension MyStacksViewController: KeyboardAvoidable {
    
    var layoutConstraintsToAdjust: [NSLayoutConstraint] {
        return [collectionViewBottomConstraint]
    }
}

// MARK:- UISearchBarDelegate
extension MyStacksViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        toggleSearchVisibility()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        stacksCollectionController.performSearch(query: searchText)
        cardsCollectionController.performSearch(query: searchText)
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch selectedScope {
        case 0:
            collectionView.delegate = stacksCollectionController
            collectionView.dataSource = stacksCollectionController
        case 1:
            collectionView.delegate = cardsCollectionController
            collectionView.dataSource = cardsCollectionController
        default: break
        }
        collectionView.reloadData()
    }
}
