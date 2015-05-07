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
        let newSubject = Subject(name: "New Subject")
        User.sharedInstance().addSubject(newSubject)
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
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
        let subject = User.sharedInstance().subjects[indexPath.item]
        
        let flashCardsVC = self.storyboard?.instantiateViewControllerWithIdentifier("flashCardsVC") as! FlashCardsTableViewController
            flashCardsVC.subject = subject
        
        self.navigationController?.pushViewController(flashCardsVC, animated: true)
    }
}
