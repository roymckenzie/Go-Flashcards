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
    var _stackVCDelegate: StackViewController!
    
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
        if section == 0 {
            return 30
        }
        return 0.00001
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if section == 0 {
            let headerView = view as! UITableViewHeaderFooterView
                headerView.contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
                headerView.textLabel.textColor = UIColor.whiteColor()
                headerView.textLabel.frame = CGRectOffset(headerView.textLabel.frame, headerView.textLabel.frame.origin.x, 23)
                headerView.textLabel.font = UIFont(name: "Avenir-Book", size: 13)
            
            let headerViewWidth = headerView.frame.width
            let button: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                button.tintColor = UIColor.whiteColor()
                button.frame = CGRectOffset(button.frame, headerViewWidth - 41, 4)
                button.addTarget(self, action: "addCard", forControlEvents: .TouchUpInside)
            headerView.addSubview(button)
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Cards"
        }
        return ""
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("flashCardCell", forIndexPath: indexPath) as! FlashCardsTableViewCell
        let card: Card
        if indexPath.section == 0 {
            card = subject.visibleCards()[indexPath.item]
            cell.backgroundColor = UIColor.clearColor()
            cell.togleVisibilityButton.setImage(UIImage(named: "Eye Visible"), forState: .Normal)
            cell.flashCardLabel.textColor = UIColor.whiteColor()
            cell.flashCardLabel.alpha = 1.0
        }else{
            card = subject.hiddenCards()[indexPath.item]
            cell.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.1)
            cell.togleVisibilityButton.setImage(UIImage(named: "Eye Hidden"), forState: .Normal)
            cell.flashCardLabel.textColor = UIColor.blackColor()
            cell.flashCardLabel.alpha = 0.5
        }
        
        cell.card = card
        cell._flashCardsTableView = self
        let bgView = UIView()
            bgView.backgroundColor = UIColor.blackColor()
        
        cell.selectedBackgroundView = bgView
        
        cell.tintColor = UIColor.whiteColor()
        cell.flashCardLabel.text = card.topic

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
        let deleteButton = UITableViewRowAction(style: .Default, title: "Trash") { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            let card: Card
            if indexPath.section == 0 {
                card = self.subject.visibleCards()[indexPath.item]
            }else{
                card = self.subject.hiddenCards()[indexPath.item]
            }
            self.subject.destroyCard(card)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        deleteButton.backgroundColor = UIColor(red: 0.94, green: 0.63, blue: 0.34, alpha: 1)
        return [deleteButton]
    }
    
    func addCard() {
        
        if _stackVCDelegate.editMode == nil {
            let _subject    = _stackVCDelegate.subject
            User.sharedInstance().addSubject(_subject)
            _stackVCDelegate.editMode = true
        }
        
        let flashCardVC = self.storyboard?.instantiateViewControllerWithIdentifier("flashCardVC") as! FlashCardViewController
        flashCardVC.subject = subject
        self.presentViewController(flashCardVC, animated: true, completion: nil)
    }
    
}

class FlashCardsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var flashCardLabel: UILabel!
    @IBOutlet weak var togleVisibilityButton: UIButton!
    
    var card: Card!
    weak var _flashCardsTableView: FlashCardsTableViewController!
    
    @IBAction func toggleVisibility(button: UIButton) {
        card.hidden == true ? card.subject.unHideCard(card) : card.subject.hideCard(card)
        _flashCardsTableView.tableView.reloadData()
    }
}
