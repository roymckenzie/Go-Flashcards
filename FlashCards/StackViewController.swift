//
//  StackViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/7/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation
import UIKit

class StackViewController: UIViewController {
    
    @IBOutlet weak var cardsTableContainer: UIView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var buttonBottomLayoutGuide: NSLayoutConstraint!
    
    var stack:    Stack!
    var editMode:   Bool?
    var _flashCardsTableVC: FlashCardsTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if editMode == true {
            nameTextField.text = stack.name
        }
        
        if stack == nil {
            stack = Stack.new
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(StackViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StackViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        _flashCardsTableVC = self.storyboard?.instantiateViewController(withIdentifier: "flashCardsTableVC") as! FlashCardsTableViewController
        _flashCardsTableVC.stack = stack
        _flashCardsTableVC._stackVCDelegate = self
        addChildViewController(_flashCardsTableVC)
        _flashCardsTableVC.view.frame = cardsTableContainer.bounds
        
        cardsTableContainer.addSubview(_flashCardsTableVC.view)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func keyboardDidShow(_ notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        let value: NSValue = info.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardSize: CGSize = value.cgRectValue.size
        buttonBottomLayoutGuide.constant = keyboardSize.height
        
        UIView.animate(withDuration: 0.2,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    func keyboardWillHide(_ notification: Notification) {
        buttonBottomLayoutGuide.constant = 0
        
        
        UIView.animate(withDuration: 0.2,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    @IBAction func saveSubject(_ sender: AnyObject) {
        guard let name = nameTextField.text, name.characters.count > 0 else {
            showAlert(title: "Your stack must have a name.", message: "Please give your stack a name to continue.")
            return
        }

        view.endEditing(true)

        stack.name = name
        stack.save()
            .then { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }
            .catch { [weak self] error in
                self?.showAlert(title: "Could not save new stack", error: error)
            }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension StackViewController: UITextFieldDelegate, UITextViewDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
}
