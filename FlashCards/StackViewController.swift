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
    
    var subject:    Subject!
    var editMode:   Bool?
    var _flashCardsTableVC: FlashCardsTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if editMode == true {
            nameTextField.text = subject.name
        }
        
        if subject == nil {
            subject = Subject(name: "Untitled")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(StackViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StackViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        _flashCardsTableVC = self.storyboard?.instantiateViewController(withIdentifier: "flashCardsTableVC") as! FlashCardsTableViewController
        _flashCardsTableVC.subject = subject
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
        nameTextField.resignFirstResponder()
        if editMode == true, let subjectName = nameTextField.text {
            subject.name = subjectName
            DataManager.current.updateSubject(subject)
        }else{
            guard let name        = nameTextField.text else { return }
            let _subject    = Subject(name: name)
            DataManager.current.addSubject(_subject)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension StackViewController: UITextFieldDelegate, UITextViewDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == "Stack name" {
            textField.text = ""
        }
        textField.font = UIFont(name: "Avenir-Heavy", size: 24)
        textField.textColor = UIColor.white
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == "" {
            textField.text = "Stack name"
        }
        textField.font = UIFont(name: "Avenir-HeavyOblique", size: 24)
        textField.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
}
