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

class NewStackViewController: UIViewController {

    @IBOutlet weak var stackNameTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    var statusBarHidden = false

    var stack: Stack!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let placeholderAttributes = [
            NSForegroundColorAttributeName: UIColor.white.withAlphaComponent(0.3),
            NSFontAttributeName: UIFont.systemFont(ofSize: 35, weight: UIFontWeightSemibold)
        ]
        
        let placeholderString = NSAttributedString(string: "Political Science", attributes: placeholderAttributes)
        stackNameTextField.attributedPlaceholder = placeholderString
        
        stackNameTextField.becomeFirstResponder()
        
        if let stack = self.stack {
            stackNameTextField.text = stack.name
        }
        
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
    
    @IBAction func deleteStack(_ sender: Any) {
        let realm = try! Realm()
        try? realm.write {
            stack.deleted = Date()
            stack.modified = Date()
        }
    }
    
    @available(iOS 10.0, *)
    @IBAction func share(_ sender: UIButton) {
        let record = stack.record
        let share = CKShare(rootRecord: record)
        share.publicPermission = .readWrite
        share[CKShareTitleKey] = "\(stack.name)" as NSString
        share[CKShareTypeKey] = "com.roymckenzie.FlashCards" as NSString
        let container = CKContainer.default()
        
        let sharingController = UICloudSharingController { controller, prepareCompletionHandler in
            
            let operation = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.modifyRecordsCompletionBlock = { _, _, error in
                prepareCompletionHandler(share, container, error)
            }
            CKContainer.default().privateCloudDatabase.add(operation)
        }
        
        sharingController.popoverPresentationController?.sourceView = sender
        sharingController.availablePermissions = [.allowPublic, .allowReadWrite]
        sharingController.delegate = self
        
        present(sharingController, animated: true, completion: nil)
    }
    
    @IBAction func next(_ sender: Any) {
        guard let stackName = stackNameTextField.text else {
            return
        }

        if stack == nil {
            stack = Stack()
        }
        
        let realm = try! Realm()
        
        try? realm.write {
            stack?.name = stackName
            stack?.modified = Date()
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

@available(iOS 10.0, *)
extension NewStackViewController: UICloudSharingControllerDelegate {
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return stack.name
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        NSLog("Could not save share: \(error)")
    }
}

extension NewStackViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        nextButton.isEnabled = string.characters.count > 0
    
        return true
    }
}
