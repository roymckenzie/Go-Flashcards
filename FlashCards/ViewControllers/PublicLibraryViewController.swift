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
    
    lazy var settingsController: SearchSettingsTableDelegateDataSource = {
        return SearchSettingsTableDelegateDataSource(tableView: self.settingsTableView)
    }()
    
    // MARK:- Outlets
    @IBOutlet weak var quizletImageView: UIImageView!
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
    
    private func setupSettingsTableView() {
        settingsController.didSelect = { [weak self] _ in
            self?.resizeFilterSettingsView()
        }
        
        settingsController.didDeselect = { [weak self] _ in
            self?.resizeFilterSettingsView()
        }
    }
    
    private func resizeFilterSettingsView() {
        settingsTableView.beginUpdates()
        settingsTableView.endUpdates()

        let height: CGFloat
        
        if let row = settingsTableView.indexPathForSelectedRow?.row, (row == 1 || row == 3) {
            height = 252
        } else {
            height = 132
        }
        
        self.tableViewHeightConstraint.constant = height

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

final class SearchSettingsTableDelegateDataSource: NSObject {
    
    weak var tableView: UITableView!
    
    var didSelect: ((IndexPath) -> Void)?
    var didDeselect: ((IndexPath) -> Void)?
    
    var frontLanguagePicker = UIPickerView()
    var backLanguagePicker = UIPickerView()
    
    lazy var frontPickerController: LanguageDataSource = {
        return LanguageDataSource(pickerView: self.frontLanguagePicker)
    }()

    lazy var backPickerController: LanguageDataSource = {
        return LanguageDataSource(pickerView: self.backLanguagePicker)
    }()

    init(tableView: UITableView) {
        super.init()
        self.tableView = tableView
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        
        backLanguagePicker.frame.size.height = 120
        backLanguagePicker.frame.size.width = tableView.frame.width

        frontLanguagePicker.frame.size.height = 120
        frontLanguagePicker.frame.size.width = tableView.frame.width
        
        frontPickerController.pickerView.reloadAllComponents()
        backPickerController.pickerView.reloadAllComponents()
    }
}

final class LanguageDataSource: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    weak var pickerView: UIPickerView!
    
    var dataSource = [(code: String, name: String)]()
    
    init(pickerView: UIPickerView) {
        super.init()
        
        self.pickerView = pickerView
        
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.tintColor = .white
        
        let currentLocale = Locale.autoupdatingCurrent.languageCode
        
        let localeIds = Locale.isoLanguageCodes
        let localeNames = localeIds.flatMap { (code: $0, name: Locale.current.localizedString(forIdentifier: $0) ?? "") }
        
        let filteredNames = localeNames.filter { !$0.name.characters.isEmpty }
        
        var sortedNames = filteredNames.sorted { $0.1 < $1.1}
        let currentLocaleIndex = sortedNames.index { $0.code == currentLocale }
        
        if let currentLocaleIndex = currentLocaleIndex {
            let object = sortedNames[currentLocaleIndex]
            sortedNames.remove(at: currentLocaleIndex)
            sortedNames.insert(object, at: 0)
        }
        
        dataSource.append(contentsOf: sortedNames)
        
        pickerView.reloadAllComponents()
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
   
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dataSource[row].name
    }
}

extension SearchSettingsTableDelegateDataSource: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell
        
        switch indexPath.row {
        case 0:
            cell = UITableViewCell(style: .default, reuseIdentifier: "hasImagesCell")
            cell.accessoryView = UISwitch()
        case 1:
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "languageCell")
            cell.accessoryType = .disclosureIndicator
        case 2:
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "frontLanguagePickerCell")
            cell.addSubview(frontLanguagePicker)
        case 3:
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "languageCell")
            cell.accessoryType = .disclosureIndicator
        case 4:
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "backLanguagePickerCell")
            cell.addSubview(backLanguagePicker)
        default: cell = UITableViewCell()
        }
        
        cell.clipsToBounds = true
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Only Stacks with images"
        case 1:
            cell.textLabel?.text = "English"
            cell.detailTextLabel?.text = "Front Language"
        case 3:
            cell.textLabel?.text = "English"
            cell.detailTextLabel?.text = "Back Language"
        default: break
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelect?(indexPath)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        didDeselect?(indexPath)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.indexPathForSelectedRow == indexPath {
            tableView.deselectRow(at: indexPath, animated: true)
            didDeselect?(indexPath)
            return nil
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let selectedIndexPath = tableView.indexPathForSelectedRow
        
        switch (indexPath.row, selectedIndexPath?.row) {
        case (2, let row):
            if row == 1 {
                return 120
            }
            return .leastNormalMagnitude
        case (4, let row):
            if row == 3 {
                return 120
            }
            return .leastNormalMagnitude
        default:
            return UITableViewAutomaticDimension
        }
    }
}
