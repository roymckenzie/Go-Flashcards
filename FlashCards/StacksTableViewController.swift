//
//  StacksTableViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/5/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//


import UIKit

class StacksTableViewController: UITableViewController {
    
    @IBAction func addSubject(_ sender: AnyObject) {
        let subjectVC = self.storyboard?.instantiateViewController(withIdentifier: "stackVC") as! StackViewController
        self.navigationController?.present(subjectVC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DataManager.current.refreshSubjects()
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataManager.current.subjects.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.00001
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableView.frame.width / 2.0523255814
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stackCell", for: indexPath) as! StackTableViewCell
        let subject = DataManager.current.subjects[indexPath.item]
        cell.subject = subject
        cell.tableView = self
        cell.stackNameLabel.text = subject.name
        let cardCountText = subject.cards.count == 1 ? "\(subject.cards.count) card" : "\(subject.cards.count) cards"
        cell.cardCountLabel.text = cardCountText
        cell.tintColor = UIColor.white
        
        let bgView = UIView()
        bgView.backgroundColor = UIColor.black
        
        cell.selectedBackgroundView = bgView
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DataManager.current.refreshSubjects()
        let subject = DataManager.current.subjects[indexPath.item]
        
        let flashCardsVC = self.storyboard?.instantiateViewController(withIdentifier: "flashCardsVC") as! FlashCardsViewController
            flashCardsVC.subject = subject
        
        self.navigationController?.pushViewController(flashCardsVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        //
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Trash") { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
            let subject = DataManager.current.subjects[indexPath.item]
            DataManager.current.removeSubject(subject)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        deleteButton.backgroundColor = UIColor(red: 0.94, green: 0.63, blue: 0.34, alpha: 1)
        return [deleteButton]
    }
}

class StackTableViewCell: UITableViewCell {

    @IBOutlet weak var stackNameLabel: UILabel!
    @IBOutlet weak var cardCountLabel: UILabel!
    
    var subject: Subject!
    weak var tableView: StacksTableViewController!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textLabel?.textColor = UIColor.white
        self.textLabel?.font = UIFont(name: "Avenir-Book", size: 16)
    }
    
    @IBAction func editStack(_ sender: AnyObject) {
        
        let stackVC = tableView.storyboard?.instantiateViewController(withIdentifier: "stackVC") as! StackViewController
        stackVC.subject = subject
        stackVC.editMode = true
        
        self.setEditing(false, animated: true)
        tableView.navigationController?.present(stackVC, animated: true, completion: nil)
    }
    
}
