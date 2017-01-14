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
            showAlert(title: "Uh oh...", message: "Your new Stack must have a name.")
            return
        }
        
        let realm = try! Realm()
        
        try? realm.write {
            let stack = Stack()
            stack.name = stackName
            stack.modified = Date()
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
