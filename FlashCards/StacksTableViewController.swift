//
//  StacksTableViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/5/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//


import UIKit
import FlashCardsKit


class StacksTableViewController: UITableViewController {
    
    @IBAction func addSubject(sender: AnyObject) {
        let subjectVC = self.storyboard?.instantiateViewControllerWithIdentifier("stackVC") as! StackViewController
        self.navigationController?.presentViewController(subjectVC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        User.sharedInstance().refreshSubjects()
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return User.sharedInstance().subjects.count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.00001
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.tableView.frame.width / 2.0523255814
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("stackCell", forIndexPath: indexPath) as! StackTableViewCell
        let subject = User.sharedInstance().subjects[indexPath.item]
        cell.subject = subject
        cell.tableView = self
        cell.stackNameLabel.text = subject.name
        let cardCountText = subject.cards.count == 1 ? "\(subject.cards.count) card" : "\(subject.cards.count) cards"
        cell.cardCountLabel.text = cardCountText
        cell.tintColor = UIColor.whiteColor()
        
        let bgView = UIView()
        bgView.backgroundColor = UIColor.blackColor()
        
        cell.selectedBackgroundView = bgView
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        User.sharedInstance().refreshSubjects()
        let subject = User.sharedInstance().subjects[indexPath.item]
        
        let flashCardsVC = self.storyboard?.instantiateViewControllerWithIdentifier("flashCardsVC") as! FlashCardsViewController
            flashCardsVC.subject = subject
        
        self.navigationController?.pushViewController(flashCardsVC, animated: true)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        //
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteButton = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Trash") { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            let subject = User.sharedInstance().subjects[indexPath.item]
            User.sharedInstance().removeSubject(subject)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
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
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textLabel?.textColor = UIColor.whiteColor()
        self.textLabel?.font = UIFont(name: "Avenir-Book", size: 16)
    }
    
    @IBAction func editStack(sender: AnyObject) {
        
        let stackVC = tableView.storyboard?.instantiateViewControllerWithIdentifier("stackVC") as! StackViewController
        stackVC.subject = subject
        stackVC.editMode = true
        
        self.setEditing(false, animated: true)
        tableView.navigationController?.presentViewController(stackVC, animated: true, completion: nil)
    }
    
}
