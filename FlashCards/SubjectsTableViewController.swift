//
//  SubjectsTableViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/5/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//


import UIKit
import FlashCardsKit


class SubjectsTableViewController: UITableViewController {
    
    @IBAction func addSubject(sender: AnyObject) {
        let subjectVC = self.storyboard?.instantiateViewControllerWithIdentifier("subjectVC") as! SubjectViewController
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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("subjectCell", forIndexPath: indexPath) as! UITableViewCell
        let subject = User.sharedInstance().subjects[indexPath.item]
        
        cell.textLabel?.text = subject.name
        cell.accessoryType = .DisclosureIndicator
        cell.tintColor = UIColor.whiteColor()
        
        let bgView = UIView()
        bgView.backgroundColor = UIColor.blackColor()
        
        cell.selectedBackgroundView = bgView
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        User.sharedInstance().refreshSubjects()
        let subject = User.sharedInstance().subjects[indexPath.item]
        
        let flashCardsVC = self.storyboard?.instantiateViewControllerWithIdentifier("flashCardsVC") as! FlashCardsTableViewController
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
        let deleteButton = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Remove") { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            let subject = User.sharedInstance().subjects[indexPath.item]
            User.sharedInstance().removeSubject(subject)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        deleteButton.backgroundColor = UIColor(red: 0.94, green: 0.63, blue: 0.34, alpha: 1)
        let editButton = UITableViewRowAction(style: .Default, title: "Edit") { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            let subject = User.sharedInstance().subjects[indexPath.item]
            
            let subjectVC = self.storyboard?.instantiateViewControllerWithIdentifier("subjectVC") as! SubjectViewController
                subjectVC.subject = subject
                subjectVC.editMode = true
            
            self.setEditing(false, animated: true)
            self.navigationController?.presentViewController(subjectVC, animated: true, completion: nil)
        }
        editButton.backgroundColor = UIColor(red: 0.27, green: 0.43, blue: 0.45, alpha: 1)

        
        return [deleteButton,editButton]
    }
}
