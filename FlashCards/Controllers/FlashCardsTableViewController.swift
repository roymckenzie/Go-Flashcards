//
//  FlashCardsTableViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit
import FlashCardsKit


class FlashCardsTableViewController: UITableViewController {
    
    var subject: Subject!
    
    @IBAction func addCard(sender: AnyObject) {
        let flashCardVC = self.storyboard?.instantiateViewControllerWithIdentifier("flashCardVC") as! FlashCardViewController
            flashCardVC.subject = subject
        self.presentViewController(flashCardVC, animated: true, completion: nil)
    }
    
    @IBAction func arrangeCards(sender: AnyObject) {
        self.editing = self.editing ? false : true
        let button = sender as! UIBarButtonItem
        
        if self.editing {
            button.title = "Done"
        }else{
            button.title = "Arrange"
            self.tableView.reloadData()
        }
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
        if section == 0 {
            return subject.visibleCards().count
        }
        return subject.hiddenCards().count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.00001
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
            headerView.contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
            headerView.textLabel.textColor = UIColor.whiteColor()
            headerView.textLabel.font = UIFont(name: "Avenir-Book", size: 13)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Visible Cards"
        }
        return "Hidden Cards"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("flashCardCell", forIndexPath: indexPath) as! UITableViewCell
        let card: Card
        if indexPath.section == 0 {
            card = subject.visibleCards()[indexPath.item]
            cell.accessoryType = .Checkmark
        }else{
            card = subject.hiddenCards()[indexPath.item]
            cell.accessoryType = .None
        }
        
        let bgView = UIView()
            bgView.backgroundColor = UIColor.blackColor()
        
        cell.selectedBackgroundView = bgView
        
        cell.tintColor = UIColor.whiteColor()
        cell.textLabel?.text = card.topic

        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if tableView.editing {
            return .None
        }
        return .Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let card = subject.cards[indexPath.item]
        subject.destroyCard(card)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let _card = sourceIndexPath.section == 0 ? subject.visibleCards()[sourceIndexPath.item] : subject.hiddenCards()[sourceIndexPath.item]
        _card.hidden = destinationIndexPath.section == 0 ? false : true
        _card.order = destinationIndexPath.item
        User.sharedInstance().saveSubjects()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let _card = indexPath.section == 0 ? subject.visibleCards()[indexPath.item] : subject.hiddenCards()[indexPath.item]
        let flashCardVC = self.storyboard?.instantiateViewControllerWithIdentifier("flashCardVC") as! FlashCardViewController
            flashCardVC.card = _card
            flashCardVC.subject = subject
            flashCardVC.editMode = true
        self.presentViewController(flashCardVC, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteButton = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Remove") { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            let card = self.subject.cards[indexPath.item]
            self.subject.destroyCard(card)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        deleteButton.backgroundColor = UIColor(red: 0.94, green: 0.63, blue: 0.34, alpha: 1)
        let hideButton = UITableViewRowAction(style: .Default, title: "Hide") { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            let _card = self.subject.visibleCards()[indexPath.item]
            _card.hidden = true
            tableView.reloadData()
        }
        hideButton.backgroundColor = UIColor(red: 0.27, green: 0.43, blue: 0.45, alpha: 1)
        let showButton = UITableViewRowAction(style: .Default, title: "Show") { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            let _card = self.subject.hiddenCards()[indexPath.item]
            _card.hidden = false
            tableView.reloadData()
        }
        showButton.backgroundColor = UIColor(red: 0.27, green: 0.43, blue: 0.45, alpha: 1)

        if indexPath.section == 0 {
            return [deleteButton,hideButton]
        }else{
            return [deleteButton,showButton]
        }
    }
    
}
