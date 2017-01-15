//
//  StacksViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/25/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift

final class StacksViewController: UIViewController {
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
        let attributes = [NSForegroundColorAttributeName: UIColor.white]
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(startSync), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Syncing", attributes: attributes)
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
        
        addKeyboardListeners()
        collectionViewBottomConstraint.constant = 0
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        removeKeyboardListeners()
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
        
        stacksCollectionController.didSelectItem = { [weak self] stack, _ in
            self?.performSegue(withIdentifier: "showCards", sender: stack)
        }
        
        cardsCollectionController.didSelectItem = { [weak self] card, _ in
            self?.performSegue(withIdentifier: "showCard", sender: card)
        }
        
        stacksCollectionController.createNewItem = { [weak self] in
            self?.performSegue(withIdentifier: "newStack", sender: nil)
        }
        
        collectionView.addSubview(refreshControl)
    }
    
    func startSync(_ refreshControl: UIRefreshControl) {
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
extension StacksViewController: KeyboardAvoidable {
    
    var layoutConstraintsToAdjust: [NSLayoutConstraint] {
        return [collectionViewBottomConstraint]
    }
}

// MARK:- UISearchBarDelegate
extension StacksViewController: UISearchBarDelegate {
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

final class StacksCollectionViewController: NSObject {
    
    private weak var collectionView: UICollectionView!
    
    let realm = try! Realm()
    var realmNotificationToken: NotificationToken?
    
    var dataSource: Results<Stack> {
        let undeletedPredicate = NSPredicate(format: "deleted == nil")
        guard let query = query else {
            return realm.objects(Stack.self).filter(undeletedPredicate)
        }
        let predicate = NSPredicate(format: "name CONTAINS[c] %@", query)
        return realm.objects(Stack.self).filter(undeletedPredicate).filter(predicate)
    }
    
    fileprivate var query: String? {
        didSet {
            collectionView.alwaysBounceVertical = query == nil
        }
    }
    
    var didSelectItem: ((Stack, IndexPath) -> ())?
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
        NSLog("StacksCollectionViewController denit")
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
            cell.textLabel.text = "Add your\nfirst Stack"
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
    
    var didSelectItem: ((Card, IndexPath) -> ())?
    
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
