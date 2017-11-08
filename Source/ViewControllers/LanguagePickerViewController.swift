//
//  LanguagePickerViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/26/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

final class LanguagePickerViewController: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    private weak var pickerView: UIPickerView!
    private var dataSource = [(code: String, name: String)]()
    
    var didUpdateLanguage: ((String, String) -> Void)?
    
    init(pickerView: UIPickerView) {
        super.init()
        
        self.pickerView = pickerView
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        let currentLocale = Locale.autoupdatingCurrent.languageCode
        
        let localeIds = Locale.isoLanguageCodes
        let localeNames = localeIds.flatMap { (code: $0, name: Locale.current.localizedString(forIdentifier: $0) ?? "") }
        
        let filteredNames = localeNames.filter { !$0.name.isEmpty }
        
        var sortedNames = filteredNames.sorted { $0.1 < $1.1}
        let currentLocaleIndex = sortedNames.index { $0.code == currentLocale }
        
        if let currentLocaleIndex = currentLocaleIndex {
            let object = sortedNames[currentLocaleIndex]
            sortedNames.remove(at: currentLocaleIndex)
            sortedNames.insert(object, at: 0)
            let nilLanguage = (code: "", name: "None selected")
            sortedNames.insert(nilLanguage, at: 0)
        }
        
        dataSource.append(contentsOf: sortedNames)
        
        pickerView.reloadAllComponents()
    }
    
    func selectRowWith(languageCode: String?) {
        guard let languageCode = languageCode else { return }
        guard let index = dataSource.index(where: { $0.code == languageCode }) else { return }
        pickerView.selectRow(index, inComponent: 0, animated: false)
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
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let attributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
        let name = dataSource[row].name
        return NSAttributedString(string: name, attributes: attributes)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let languageCode = dataSource[row].code
        let languageName = dataSource[row].name
        didUpdateLanguage?(languageCode, languageName)
    }
}
