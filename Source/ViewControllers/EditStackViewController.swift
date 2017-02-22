//
//  EditStackViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/8/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit
import CloudKit
import RealmSwift

private let UhOh = NSLocalizedString("Uh oh...", comment: "Error alert title")
private let StackMustHaveName = NSLocalizedString("Your new Stack must have a name.", comment: "error alert details")
private let CopyShareLink = NSLocalizedString("Copy Share Link", comment: "Text for share stack prompt")
private let DeleteStackQuestion = NSLocalizedString("Delete Stack?", comment: "prompt for deleting stack")
private let Delete = NSLocalizedString("Delete", comment: "delet option")
private let Cancel = NSLocalizedString("Cancel", comment: "delet option")
private let CouldNotDeleteShare = NSLocalizedString("Could not delete share", comment: "alert for couldn't delete share")
private let CouldNotShareStack = NSLocalizedString("Could not share this Stack.", comment: "alert for couldn't share stack")
private let LoadingShareInfo = NSLocalizedString("Loading Share Info", comment: "Loading info from cloudkit for share")
private let DeleteSharedStack = NSLocalizedString("Delete Shared Stack", comment: "description for deleting shared stack")
private let DeleteStack = NSLocalizedString("Delete Stack", comment: "description for deleting stack")
private let ManageSharing = NSLocalizedString("Manage Sharing", comment: "manage sharing of a stack")
private let ShareStack = NSLocalizedString("Share Stack", comment: "share a stack description")
private let Sharing = NSLocalizedString("Sharing", comment: "sharing header description string")
private let Name = NSLocalizedString("Name", comment: "name header description string")
private let UnmasterAllCards = NSLocalizedString("Unmaster all Cards", comment: "description for unmastering all cards")
private let StudyReminder = NSLocalizedString("Study Reminder", comment: "Study reminder section header")

final class EditStackViewController: UIViewController, RealmNotifiable {
    
    var stack: Stack!
    
    var realmNotificationToken: NotificationToken?
    
    lazy var tableController: EditStackTableController = {
        return EditStackTableController(stack: self.stack, tableView: self.tableView)
    }()
    
    @IBOutlet weak var tableView: UITableView!
    
    var manageShareCell: UITableViewCell {
        return tableView.cellForRow(at: IndexPath(row: 0, section: 1))!
    }
    
    var deleteStackShareCell: UITableViewCell {
        return tableView.cellForRow(at: IndexPath(row: 1, section: 2))!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationController.setStackNotifications()
        
        setupTableController()
        
        startRealmNotification { [weak self] _ in
            self?.tableView.reloadData()
            if self?.stack.isInvalidated == true {
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    /// Mark setup tableView controller
    private func setupTableController() {
        tableController.didSelectRow = { [weak self] indexPath in
            self?.didSelectRow(indexPath)
        }
        tableController.reloadData()
    }
    
    /// Actions for didSelectRow delegate method for tableView
    func didSelectRow(_ indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (1, 0):
            if #available(iOS 10.0, *) {
                handleShare()
            }
        case (1, 1):
            if #available(iOS 10.0, *) {
                guard let cell = tableView.cellForRow(at: indexPath) else { return }
                showCopyMenu(atCell: cell)
            }
        case (3, 0):
            unmasterAllCards()
            tableView.reloadData()
        case (3, 1):
            areYouSureDelete()
        default: break
        }
    }
    
    /// Set all cards to unmastered
    private func unmasterAllCards() {
        let realm = try! Realm()
        
        try? realm.write {
            stack.cards.forEach({
                $0.mastered = nil
                $0.modified = Date()
            })
            stack.preferences?.modified = Date()
        }
    }
    
    /// Manage current share with UICloudSharingController
    @available(iOS 10.0, *)
    func handleShare() {
        
        guard let share = tableController.share as? CKShare else {
            createShare()
            return
        }

        let vc = UICloudSharingController(share: share, container: CKContainer.default())
        vc.popoverPresentationController?.sourceView = manageShareCell.textLabel

        present(vc, animated: true, completion: nil)
    }
    
    /// Create share for Stack with UICloudSharingController UI
    @available(iOS 10.0, *)
    func createShare() {
        
        let record = stack.record
        let share = CKShare(rootRecord: record)
        share.publicPermission = .readWrite
        share[CKShareTitleKey] = stack.name as NSString
        share[CKShareThumbnailImageDataKey] = UIImagePNGRepresentation(#imageLiteral(resourceName: "app-icon-large")) as NSData?
        share[CKShareTypeKey] = "com.roymckenzie.FlashCards" as NSString
        
        let sharingController = UICloudSharingController { controller, prepareCompletionHandler in
            
            let container = CKContainer.default()
            let operation = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.modifyRecordsCompletionBlock = { _, _, error in
                prepareCompletionHandler(share, container, error)
            }
            CKContainer.default().privateCloudDatabase.add(operation)
        }
        
        sharingController.popoverPresentationController?.sourceView = manageShareCell.textLabel
        
        sharingController.availablePermissions = [.allowPublic, .allowReadWrite, .allowPrivate]
        sharingController.delegate = self
        
        present(sharingController, animated: true, completion: nil)
    }
    
    /// Show copy menu
    @available(iOS 10.0, *)
    func showCopyMenu(atCell cell: UITableViewCell) {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        let menuItem = UIMenuItem(title: CopyShareLink, action: #selector(copyShareLink))
        menu.menuItems = [menuItem]
        menu.setTargetRect(cell.frame, in: tableView)
        menu.setMenuVisible(true, animated: true)
    }
    
    /// Copy share link
    @available(iOS 10.0, *)
    func copyShareLink() {
        guard let share = tableController.share as? CKShare, let shareUrl = share.url?.absoluteString else { return }
        UIPasteboard.general.string = shareUrl
    }
    
    // So UIMenus can show in this view
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    /// Show menu confirming delete of Stack
    private func areYouSureDelete() {
        let alertStyle: UIAlertControllerStyle
        if traitCollection.horizontalSizeClass == .regular {
            alertStyle = .alert
        } else {
            alertStyle = .actionSheet
        }
        let actionSheet = UIAlertController(title: DeleteStackQuestion, message: nil, preferredStyle: alertStyle)
        actionSheet.popoverPresentationController?.sourceView = deleteStackShareCell.textLabel
        actionSheet.popoverPresentationController?.backgroundColor = .darkGray

        let deleteAction = UIAlertAction(title: Delete, style: .destructive) { [weak self] _ in
            if self?.stack.isSharedWithMe == true {
                self?.fetchShareToDelete()
            } else {
                self?.deleteStack()
            }
        }
        let cancelAction = UIAlertAction(title: Cancel, style: .cancel, handler: nil)
        
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    /// Delete stack
    private func deleteStack() {
        let realm = try! Realm()
        let date = Date()
        try? realm.write {

            stack.cards.forEach {
                $0.modified = date
                $0.deleted = date
            }
            
            stack.cards.setValue(date, forKey: "modified")
            stack.cards.setValue(date, forKey: "deleted")

            stack.modified = date
            stack.deleted = date
            stack.preferences?.modified = date
            stack.preferences?.deleted = date
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func fetchShareToDelete() {
        if #available(iOS 10.0, *) {
            CloudKitController
                .fetchShareFor(stack.recordID)
                .then { [weak self] share in
                    self?.delete(share)
                }
                .catch { [weak self] error in
                    if error == CloudKitControllerError.recordHasNoShare {
                        self?.deleteStack()
                    }
                    NSLog("Could not fetch share to delete. Deleting stack from")
                }
        }
    }
    
    @available(iOS 10.0, *)
    private func delete(_ share: CKShare) {
        CKContainer
            .default()
            .sharedCloudDatabase
            .delete(withRecordID: share.recordID) { [weak self] _, error in
                
                if let error = error {
                    self?.showAlert(title: CouldNotDeleteShare, error: error)
                    return
                }
                DispatchQueue.main.async {
                    self?.deleteStack()
                }
        }
    }
    
    // MARK: Cancel Editing
    @IBAction func cancel(_ sender: Any) {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Done with editing, save Stack
    @IBAction func done(_ sender: Any) {
        guard let newStackName = tableController.stackName, newStackName.characters.count > 0  else {
            showAlert(title: UhOh, message: StackMustHaveName)
            return
        }
        if newStackName != stack.name {
            let realm = try! Realm()
            try? realm.write {
                stack.name = newStackName
                stack.modified = Date()
            }
        }
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    deinit {
        stopRealmNotification()
        NSLog("[EditStackViewController] deinit")
    }

}

// MARK:- UICloudControllerDelegate
@available(iOS 10.0, *)
extension EditStackViewController: UICloudSharingControllerDelegate {
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return stack.name
    }
    
    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        return UIImagePNGRepresentation(#imageLiteral(resourceName: "app-icon-large"))
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        showAlert(title: CouldNotShareStack, error: error)
        NSLog("Could not save share: \(error)")
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        tableController.share = csc.share
        NSLog("Shared with \(csc.share?.participants.count) participants")
    }
}

final class EditStackTableController: NSObject {
    
    fileprivate let stack: Stack
    
    var share: CKRecord? {
        didSet { tableView.reloadData() }
    }
    
    var stackName: String? {
        let indexPath = IndexPath(row: 0, section: 0)
        return (tableView.cellForRow(at: indexPath) as? TextFieldCell)?.textField.text
    }
    
    var shareStackLabelText = LoadingShareInfo
    var deleteStackLabelText: String {
        if stack.isSharedWithMe {
            return DeleteSharedStack
        }
        return DeleteStack
    }
    
    fileprivate weak var tableView: UITableView!
    
    var didSelectRow: ((IndexPath) -> Void)? = nil
    
    init(stack: Stack, tableView: UITableView) {
        self.stack = stack
        self.tableView = tableView
        super.init()

        tableView.register(nibWithClass: TextFieldCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EditStackCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        loadShare()
    }
    
    open func reloadData() {
        tableView.reloadData()
    }
    
    private func loadShare() {
        if #available(iOS 10.0, *) {
            CloudKitController
                .fetchShareFor(stack.recordID)
                .then { [weak self] share in
                    self?.shareStackLabelText = ManageSharing
                    self?.share = share
                }
                .catch { [weak self] error in
                    if error == CloudKitControllerError.recordHasNoShare {
                        self?.shareStackLabelText = ShareStack
                        self?.share = nil
                    }
                    NSLog("Error fetching share: \(error)")
                }
        }
    }
    
    fileprivate var shareSectionRowCount: Int {
        if #available(iOS 10.0, *) {
            if stack.isSharedWithMe {
                return 0
            }
            if share != nil {
                return 2
            }
            return 1
        } else {
            return 0
        }
    }
}

extension EditStackTableController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return Name
        case 1:
            return Sharing
        case 2:
            return nil //StudyReminder
        case 3:
            return ""
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return shareSectionRowCount
        case 2:
            return 0 //3
        case 3:
            return 2
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.section, indexPath.row) {
        case (3, 0):
            if stack.masteredCards.count > 0 {
                return UITableViewAutomaticDimension
            } else {
                return .leastNormalMagnitude
            }
        case (2, let row):
            switch row {
            case 0:
                return UITableViewAutomaticDimension
            default:
                if stack.activeNotification {
                    return UITableViewAutomaticDimension
                }
                return .leastNormalMagnitude
            }
        default: return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && stack.isSharedWithMe {
            return .leastNormalMagnitude
        }
        if section == 2 {
            return .leastNormalMagnitude
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.clipsToBounds = true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0,0):
            return tableView.dequeueCell(withNibClass: TextFieldCell.self, indexPath: indexPath)
        case (2, 1), (2, 2):
            return UITableViewCell(style: .value1, reuseIdentifier: "DetailCell")
        default:
            return tableView.dequeueReusableCell(withIdentifier: "EditStackCell", for: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Default cell styling
        cell.textLabel?.textColor = .white
        cell.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        cell.contentView.backgroundColor = .clear
        cell.textLabel?.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.clipsToBounds = true
        cell.accessoryView = nil

        switch (indexPath.section, indexPath.row, cell) {
        case (0, 0, let cell as TextFieldCell):
            cell.textField.text = stack.name
        case (1, 0, _):
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = shareStackLabelText
        case (1, 1, _):
            if #available(iOS 10.0, *) {
                guard let shareUrl = (share as? CKShare)?.url?.absoluteString else { return }
                cell.textLabel?.text = shareUrl
            }
        case (2, 0, _):
            let toggleSwitch = UISwitch()
            toggleSwitch.isOn = stack.activeNotification
            toggleSwitch.addTarget(self, action: #selector(toggleNotification), for: .valueChanged)
            cell.textLabel?.text = "Remind me to study"
            cell.accessoryView = toggleSwitch
        case (2, 1, _):
            cell.textLabel?.text = "When"
            cell.detailTextLabel?.text = stack.notificationDateString
        case (2, 2, _):
            cell.textLabel?.text = "Repeat"
            cell.detailTextLabel?.text = "Never"
            cell.accessoryType = .disclosureIndicator
        case (3, 0, _):
            cell.textLabel?.text = UnmasterAllCards
            cell.textLabel?.textAlignment = .center
        case (3, 1, _):
            cell.textLabel?.textColor = .red
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = deleteStackLabelText
        default: break
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRow?(indexPath)
    }
    
    func toggleNotification(_ notificationSwitch: UISwitch) {
        if !NotificationController.appNotificationsEnabled {
//            NotificationController.showEnableNotificationsAlert(in: self)
            notificationSwitch.isOn = false
            return
        }
        
        let realm = try! Realm()
        
        let notificationOn = notificationSwitch.isOn
        
        try? realm.write {
            if stack.preferences == nil {
                stack.preferences = StackPreferences(stack: stack)
            }
            
            stack.preferences?.modified = Date()
            stack.preferences?.notificationDate = notificationOn ? Date(timeIntervalSinceNow: 30) : nil
        }
        
        NotificationController.setStackNotifications()
        
        tableView.reloadSections([2], with: UITableViewRowAnimation.automatic)
    }
}
