//
//  NewStackViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/30/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift
import CloudKit

private let UhOh = NSLocalizedString("Uh oh...", comment: "Alert title for mistake")
private let StackMustHaveName = NSLocalizedString("Your new Stack must have a name.", comment: "Details for stack name error")
class NewStackViewController: StatusBarHiddenAnimatedViewController {

    @IBOutlet weak var stackNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNameTextField()
    }
    
    private func setupNameTextField() {
        let placeholderAttributes = [
            NSForegroundColorAttributeName: UIColor.white.withAlphaComponent(0.3),
            NSFontAttributeName: UIFont.systemFont(ofSize: 35, weight: UIFontWeightSemibold)
        ]
        
        let placeholderString = NSAttributedString(string: "Political Science", attributes: placeholderAttributes)
        stackNameTextField.attributedPlaceholder = placeholderString
        stackNameTextField.becomeFirstResponder()
    }
    
    @IBAction func next(_ sender: Any) {
        guard let stackName = stackNameTextField.text, stackName.characters.count > 0 else {
            showAlert(title: UhOh, message: StackMustHaveName)
            return
        }
        
        let realm = try! Realm()
        
        try? realm.write {
            let stack = Stack()
            stack.name = stackName
            stack.modified = Date()
            let prefs = StackPreferences(stack: stack)
            realm.add(prefs, update: true)
            stack.preferences = prefs
            realm.add(stack, update: true)
        }
        
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dismiss(_ sender: Any) {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
}
