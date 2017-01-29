//
//  SearchSettingsController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/26/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

private let OnlyStacksWithImages = NSLocalizedString("Only Stacks with images",
                                                     comment: "Search filter description for images")

final class SearchSettingsTableDelegateDataSource: NSObject {
    
    var didSelect: ((IndexPath) -> Void)?
    var didDeselect: ((IndexPath) -> Void)?
    var didUpdateFilters: ((Bool, String?, String?) -> Void)?
    
    fileprivate weak var tableView: UITableView!
    fileprivate var frontLanguagePicker = UIPickerView()
    fileprivate var backLanguagePicker = UIPickerView()
    fileprivate var imageSwitch = UISwitch()
    
    fileprivate lazy var frontPickerController: LanguagePickerViewController = {
        return LanguagePickerViewController(pickerView: self.frontLanguagePicker)
    }()
    
    fileprivate lazy var backPickerController: LanguagePickerViewController = {
        return LanguagePickerViewController(pickerView: self.backLanguagePicker)
    }()
    
    fileprivate var hasImages = false
    fileprivate var frontLanguageName = "None selected"
    fileprivate var backLanguageName = "None selected"
    fileprivate var frontLanguageCode: String?
    fileprivate var backLanguageCode: String?
    
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
        
        imageSwitch.addTarget(self, action: #selector(didUpdate), for: .touchUpInside)
        
        frontPickerController.didUpdateLanguage = { [weak self] languageCode, languageName in
            self?.frontLanguageCode = languageCode
            self?.frontLanguageName = languageName
            let indexPath = IndexPath(row: 1, section: 0)
            tableView.reloadRows(at: [indexPath], with: .none)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            self?.didUpdate()
        }
        
        backPickerController.didUpdateLanguage = { [weak self] languageCode, languageName in
            self?.backLanguageCode = languageCode
            self?.backLanguageName = languageName
            let indexPath = IndexPath(row: 3, section: 0)
            tableView.reloadRows(at: [indexPath], with: .none)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            self?.didUpdate()
        }
    }
    
    func didUpdate() {
        hasImages = imageSwitch.isOn
        didUpdateFilters?(hasImages, frontLanguageCode, backLanguageCode)
    }
    
}

extension SearchSettingsTableDelegateDataSource: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell
        
        switch indexPath.row {
        case 0:
            cell = UITableViewCell(style: .default, reuseIdentifier: "hasImagesCell")
            cell.accessoryView = imageSwitch
        case 1:
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "languageCell")
            cell.accessoryType = .disclosureIndicator
        case 2:
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "frontLanguagePickerCell")
            cell.addSubview(frontLanguagePicker)
            frontPickerController.selectRowWith(languageCode: frontLanguageCode)
        case 3:
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "languageCell")
            cell.accessoryType = .disclosureIndicator
        case 4:
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "backLanguagePickerCell")
            cell.addSubview(backLanguagePicker)
            backPickerController.selectRowWith(languageCode: backLanguageCode)
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
            cell.textLabel?.text = OnlyStacksWithImages
        case 1:
            cell.textLabel?.text = frontLanguageName
            cell.detailTextLabel?.text = "Front Language"
        case 3:
            cell.textLabel?.text = backLanguageName
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
