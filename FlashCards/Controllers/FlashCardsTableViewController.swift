//
//  FlashCardsTableViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit

class FlashCardsTableViewController: UITableViewController {
    
    @IBAction func addCard(sender: AnyObject) {
        let flashCardVC = self.storyboard?.instantiateViewControllerWithIdentifier("flashCardVC") as! FlashCardViewController
        self.navigationController?.pushViewController(flashCardVC, animated: true)
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
    
    override func viewDidAppear(animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return Cards.sharedInstance().visibleCards().count
        }
        return Cards.sharedInstance().hiddenCards().count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.00001
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
        let cell = tableView.dequeueReusableCellWithIdentifier("flashCardCell") as! UITableViewCell
        let card: Card
        if indexPath.section == 0 {
            card = Cards.sharedInstance().visibleCards()[indexPath.item]
            cell.accessoryType = .Checkmark
        }else{
            card = Cards.sharedInstance().hiddenCards()[indexPath.item]
            cell.accessoryType = .None
            cell.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        }
        
        cell.tintColor = UIColor.whiteColor()
        cell.textLabel?.text = card.topic

        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let card = Cards.sharedInstance().cards[indexPath.item]
        Cards.sharedInstance().destroyCard(card)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let cards = Cards.sharedInstance()
        let card = sourceIndexPath.section == 0 ? cards.visibleCards()[sourceIndexPath.item] : cards.hiddenCards()[sourceIndexPath.item]
        card.hidden = destinationIndexPath.section == 0 ? false : true
        card.order = destinationIndexPath.item
        Cards.sharedInstance().saveCards()
    }
}
