//
//  PublicLibraryViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/22/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

class PublicLibraryViewController: UIViewController {
    
    let searchController = UISearchController(searchResultsController: nil)
    
    lazy var collectionViewController: QuizletStacksCollectionViewController = {
        return QuizletStacksCollectionViewController(collectionView: self.collectionView)
    }()
    
    // MARK:- Outlets
    @IBOutlet weak var quizletImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    
    // MARK:- Override supers
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        styleSearchBar()
        setupStackController()
        
        // Quizlet logo setup
        quizletImageView.image = quizletImageView.image?.withRenderingMode(.alwaysTemplate)
        quizletImageView.tintColor = .gray
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
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        removeKeyboardListeners()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.destination {
        case let vc as QuizletStackViewController:
            vc.stack = sender as? QuizletStack
            
        default: break
        }
    }
    
    // MARK:- Style searchBar
    private func styleSearchBar() {
        navigationItem.titleView = searchController.searchBar
        searchController.searchBar.barStyle = .black
        searchController.searchBar.placeholder = "Search Public Library Stacks"
        searchController.searchBar.tintColor = .lightGray
        searchController.searchBar.keyboardAppearance = .dark
        searchController.searchBar.delegate = self
    }
    
    // MARK:- StackController setup
    private func setupStackController() {
        collectionViewController.didSelectItem = { [weak self] stack, _ in
            self?.view.endEditing(true)
            self?.searchController.isActive = false
            self?.performSegue(withIdentifier: "showStack", sender: stack)
        }
    }
}

extension PublicLibraryViewController: KeyboardAvoidable {
    var layoutConstraintsToAdjust: [NSLayoutConstraint] {
        return [collectionViewBottomConstraint]
    }
}

extension PublicLibraryViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: nil, afterDelay: 0.5)
    }
}

extension PublicLibraryViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.characters.isEmpty {
            collectionViewController.dataSource.removeAll()
        }
    }
}

extension PublicLibraryViewController {
    
    func performSearch() {
        guard let query = searchController.searchBar.text, query.characters.count > 0 else {
            return
        }
        
        QuizletSearchController.search(query: query)
            .then { [weak self] stacks in
                self?.collectionViewController.dataSource = stacks
            }
            .catch { error in
                NSLog("Failed to fetch stacks from Quizlet error: \(error.localizedDescription)")
            }
    }
}

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

