//
//  StackViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/7/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift
import Crashlytics

private let ReminderConfirmationMessage = NSLocalizedString("We'll remind you to study this Stack at %@", comment: "")
private let ReminderConfirmationMessageTomorrow = NSLocalizedString("We'll remind you to study this Stack at %@ tomorrow", comment: "")
private let ReminderScheduled = NSLocalizedString("Reminder Scheduled", comment: "")
private let RemindMeToStudyIn = NSLocalizedString("Remind me to study in", comment: "")
private let ThirtyMinutes = NSLocalizedString("30 minutes", comment: "")
private let TwoHours = NSLocalizedString("2 hours", comment: "")
private let SixHours = NSLocalizedString("6 hours", comment: "")
private let Tomorrow = NSLocalizedString("Tomorrow", comment: "")
private let Cancel = NSLocalizedString("Cancel", comment: "")

class StackViewController: UIViewController, RealmNotifiable {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var stackTitleLabel: UILabel!
    @IBOutlet weak var stackDetailsLabel: UILabel!
    
    var stack:    Stack!
    var editMode:   Bool = false
    
    var realmNotificationToken: NotificationToken?
    
    lazy var collectionController: CardsCollectionViewController = {
        return CardsCollectionViewController(collectionView: self.collectionView, stack: self.stack)
    }()
    
    deinit {
        stopRealmNotification()
        NSLog("[StackViewController] deinit")
    }
    
    override var title: String? {
        didSet {
            stackTitleLabel.text = title
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        startRealmNotification() { [weak self] _ in
            guard let _self = self else { return }
            if _self.stack.isInvalidated || _self.stack.cards.isInvalidated || _self.stack.deleted != nil {
                let _ = _self.navigationController?.popToRootViewController(animated: true)
                return
            }
            _self.title = _self.stack.name
            _self.stackDetailsLabel.text = _self.stack.progressDescription
            _self.collectionView?.reloadData()
        }
        
        if editMode {
            title = stack.name
            stackDetailsLabel.text = stack.progressDescription
        } else {
            let realm = try? Realm()
            stack = Stack()
            
            try? realm?.write {
                realm?.add(stack)
            }
        }
        
        collectionController.didSelectItem = { [weak self] card, indexPath in
            self?.performSegue(withIdentifier: "editCardSegue", sender: card)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.destination {
        case let vc as FlashCardViewController:
            if let card = sender as? Card {
                vc.card = card
            }
            vc.stack = stack
        case let vc as EditStackViewController:
            vc.stack = stack
        default: break
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        collectionView.reloadData()
    }
    
    @IBAction func showReminderAlert(_ sender: UIBarButtonItem) {
        if !NotificationController.appNotificationsEnabled {
            NotificationController.showEnableNotificationsAlert(in: self)
            return
        }
        
        let alert = UIAlertController(title: nil, message: RemindMeToStudyIn, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = sender
        
        let remind30MinuteAction = UIAlertAction(title: ThirtyMinutes, style: .default) { [weak self] _ in
            let seconds: TimeInterval = 60*30
            self?.setNotificationForStack(in: seconds)
            
        }
        alert.addAction(remind30MinuteAction)
        let remind2HourAction = UIAlertAction(title: TwoHours, style: .default) { [weak self] _ in
            let seconds: TimeInterval = 60*60*2
            self?.setNotificationForStack(in: seconds)
            
        }
        alert.addAction(remind2HourAction)
        let remind6HourAction = UIAlertAction(title: SixHours, style: .default) { [weak self] _ in
            let seconds: TimeInterval = 60*60*6
            self?.setNotificationForStack(in: seconds)
            
        }
        alert.addAction(remind6HourAction)
        let remind24HourAction = UIAlertAction(title: Tomorrow, style: .default) { [weak self] _ in
            let seconds: TimeInterval = 60*60*24
            self?.setNotificationForStack(in: seconds)
            
        }
        alert.addAction(remind24HourAction)
        let cancelAction = UIAlertAction(title: Cancel, style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func setNotificationForStack(`in` seconds: TimeInterval) {
        let realm = try! Realm()
        
        try? realm.write {
            
            stack.preferences?.notificationDate = Date(timeIntervalSinceNow: seconds)
        }
        
        showNotificationConfirmation()
        
        Answers.logCustomEvent(withName: "Scheduled notification", customAttributes:
            [
                "Time interval": "\(seconds/60/60) Hours"
            ]
        )
        NotificationController.setStackNotifications()
    }
    
    private func showNotificationConfirmation() {
        guard let notificationDate = stack.notificationDate, stack.activeNotification else { return }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let time = formatter.string(from: notificationDate)
        var message: String = ""
        
        if Calendar.current.isDateInTomorrow(notificationDate) {
            message = ReminderConfirmationMessageTomorrow
        } else {
            message = ReminderConfirmationMessage
        }
        
        message = String(format: message, time)
        
        showAlert(title: ReminderScheduled, message: message)
    }
}

// MARK:- UITextFieldDelegate
extension StackViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
