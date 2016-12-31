//
//  NewStackViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/30/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift

class NewStackViewController: UIViewController {

    @IBOutlet weak var stackNameTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    var statusBarHidden = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let placeholderAttributes = [
            NSForegroundColorAttributeName: UIColor.white.withAlphaComponent(0.3),
            NSFontAttributeName: UIFont.systemFont(ofSize: 35, weight: UIFontWeightSemibold)
        ]
        
        let placeholderString = NSAttributedString(string: "Political Science", attributes: placeholderAttributes)
        stackNameTextField.attributedPlaceholder = placeholderString
        
        stackNameTextField.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        statusBarHidden = true
        
        UIView.animate(withDuration: 0.33) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    @IBAction func next(_ sender: Any) {
        guard let stackName = stackNameTextField.text else {
            return
        }
        
        let stack = Stack()
        stack.name = stackName
        
        let realm = try! Realm()
        
        try? realm.write {
            realm.add(stack, update: true)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dismiss(_ sender: Any) {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
}

extension NewStackViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        nextButton.isEnabled = string.characters.count > 0
    
        return true
    }
}
