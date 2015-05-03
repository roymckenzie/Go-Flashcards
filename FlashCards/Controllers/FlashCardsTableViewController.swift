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
    
    override func viewDidAppear(animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Cards.sharedInstance().cards.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("flashCardCell") as! UITableViewCell
        let data = Cards.sharedInstance().cards[indexPath.item]
        
        cell.textLabel?.text = data.question
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let card = Cards.sharedInstance().cards[indexPath.item]
        Cards.sharedInstance().destroyCard(card)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
    }
}
