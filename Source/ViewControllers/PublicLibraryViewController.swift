//
//  PublicLibraryViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/22/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

private let CouldNotAccessPublicLibrary = NSLocalizedString("Could not access Public Library", comment: "Error")
private let SearchPublicLibraryStacks = NSLocalizedString("Search Public Library Stacks", comment: "Title")

class PublicLibraryViewController: UIViewController {
    
    let searchController = UISearchController(searchResultsController: nil)
    
    lazy var settingsController: SearchSettingsTableDelegateDataSource = {
        return SearchSettingsTableDelegateDataSource(tableView: self.settingsTableView)
    }()
    
    // MARK:- Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    @IBAction func showFilter() {
        let isHidden = tableViewHeightConstraint.constant == 0
        tableViewHeightConstraint.constant = isHidden ? settingsTableView.contentSize.height : 0
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    var hasImages = false
    
    // MARK:- Override supers
    override func viewDidLoad() {
        super.viewDidLoad()
        tableViewHeightConstraint.constant = 0
        
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        styleSearchBar()
        setupStackController()
        setupSettingsTableView()

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
    
    // MARK:- Style searchBar
    private func styleSearchBar() {
        navigationItem.titleView = searchController.searchBar
        searchController.searchBar.barStyle = .black
        searchController.searchBar.placeholder = SearchPublicLibraryStacks
        searchController.searchBar.tintColor = .lightGray
        searchController.searchBar.keyboardAppearance = .dark
        searchController.searchBar.delegate = self
    }
    
    // MARK:- StackController setup
    private func setupStackController() {
    }
    
    private func setupSettingsTableView() {
        settingsController.didSelect = { [weak self] _ in
            self?.resizeFilterSettingsView()
        }
        
        settingsController.didUpdateFilters = { [weak self] hasImages, _, _ in
            self?.hasImages = hasImages
            self?.performSearch()
        }
        
        settingsController.didDeselect = { [weak self] _ in
            self?.resizeFilterSettingsView()
        }
    }
    
    private func resizeFilterSettingsView() {
        settingsTableView.beginUpdates()
        settingsTableView.endUpdates()

//        let height: CGFloat
//        
//        if let row = settingsTableView.indexPathForSelectedRow?.row, (row == 1 || row == 3) {
//            height = 252
//        } else {
//            height = 132
//        }
//        
        self.tableViewHeightConstraint.constant = 144

        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
}

extension PublicLibraryViewController: KeyboardAvoidable {
    var layoutConstraintsToAdjust: [NSLayoutConstraint] {
        return []
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
        if searchText.isEmpty {

        }
    }
}

extension PublicLibraryViewController {
    
    @objc func performSearch() {
        guard let query = searchController.searchBar.text, query.count > 0 else {
            return
        }
    }
}
