//
//  StacksTableViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/5/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//


import UIKit

class StacksTableViewController: UITableViewController {
    
    var stacks = [Stack]()
    
    @IBAction func addSubject(_ sender: AnyObject) {
        let subjectVC = self.storyboard?.instantiateViewController(withIdentifier: "stackVC") as! StackViewController
        self.navigationController?.present(subjectVC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        
        let migrator = CloudKitMigrator()
        migrator.migrateIfNeeded()
            .then { [weak self] migrationNeeded in
                if migrationNeeded {
                    self?.showAlert(title: "Migration to iCloud complete", message: "Your stacks are now stored in iCloud and will be accessible from all devices.")
                }
            }
            .always { [weak self] in
                self?.loadDataFromCloudKit()
            }
            .catch { [weak self] error in
                self?.showAlert(title: "Error migrating to iCloud", error: error)

            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        loadDataFromCloudKit()
    }
    
    private func loadDataFromCloudKit() {
        CloudKitController.current.getStacks()
            .then { [weak self] stacks in
                self?.stacks = stacks
                self?.tableView.reloadData()
            }
            .catch { [weak self] error in
                self?.showAlert(title: "Could not load stacks from iCloud", error: error)
            }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stacks.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableView.frame.width / 2.0523255814
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "stackCell", for: indexPath) as? StackTableViewCell else {
            return UITableViewCell()
        }
        
        return cell
    }
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? StackTableViewCell else { return }
        let stack = stacks[indexPath.row]
        cell.stackNameLabel.text = stack.name
        cell.editButton.tag = indexPath.row
        cell.editButton.addTarget(self, action: #selector(editStack), for: .touchUpInside)
//      let cardCountText = subject.cards.count == 1 ? "\(subject.cards.count) card" : "\(subject.cards.count) cards"
//      cell.cardCountLabel.text = cardCountText
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let stack = stacks[indexPath.row]
        
        let flashCardsVC = self.storyboard?.instantiateViewController(withIdentifier: "flashCardsVC") as! FlashCardsViewController
            flashCardsVC.stack = stack
        
        self.navigationController?.pushViewController(flashCardsVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        //
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: .default, title: "Trash") { [weak self]  _, indexPath in
            guard let stack = self?.stacks[indexPath.row] else { return }
            stack.delete()
                .then {
                    self?.stacks.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
                .catch { [weak self] error in
                    self?.showAlert(title: "Couldn't trash this stack", error: error)
                }
        }
        deleteButton.backgroundColor = .clear
        return [deleteButton]
    }
    
    func editStack(button: UIButton) {
        let stack = stacks[button.tag]
        let stackVC = storyboard?.instantiateViewController(withIdentifier: "stackVC") as! StackViewController
        stackVC.stack = stack
        stackVC.editMode = true

        navigationController?.present(stackVC, animated: true, completion: nil)
    }
}

class StackTableViewCell: UITableViewCell {

    @IBOutlet weak var stackNameLabel: UILabel!
    @IBOutlet weak var cardCountLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        selectionStyle = .none
        textLabel?.textColor = UIColor.white
        textLabel?.font = UIFont(name: "Avenir-Book", size: 16)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        editButton.removeTarget(nil, action: nil, for: .allEvents)
    }
    
    @IBAction func editStack(_ sender: AnyObject) {
        
//        let stackVC = tableView.storyboard?.instantiateViewController(withIdentifier: "stackVC") as! StackViewController
//        stackVC.subject = subject
//        stackVC.editMode = true
        
//        self.setEditing(false, animated: true)
//        tableView.navigationController?.present(stackVC, animated: true, completion: nil)
    }
    
}
