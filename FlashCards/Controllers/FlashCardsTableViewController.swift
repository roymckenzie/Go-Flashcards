//
//  FlashCardsTableViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit

class FlashCardsTableViewController: UITableViewController {
    
    var subject: Subject!
    var _stackVCDelegate: StackViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return subject.visibleCards().count
        }
        return subject.hiddenCards().count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.00001
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 30
        }
        return 0.00001
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if section == 0 {
            let headerView = view as! UITableViewHeaderFooterView
                headerView.contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
                headerView.textLabel?.textColor = UIColor.white
                headerView.textLabel?.frame = ((headerView.textLabel?.frame)?.offsetBy(dx: (headerView.textLabel?.frame.origin.x)!, dy: 23))!
                headerView.textLabel?.font = UIFont(name: "Avenir-Book", size: 13)
            
            let headerViewWidth = headerView.frame.width
            let button: UIButton = UIButton(type: .contactAdd)
                button.tintColor = UIColor.white
                button.frame = button.frame.offsetBy(dx: headerViewWidth - 41, dy: 4)
                button.addTarget(self, action: #selector(FlashCardsTableViewController.addCard), for: .touchUpInside)
            headerView.addSubview(button)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Cards"
        }
        return ""
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "flashCardCell", for: indexPath) as! FlashCardsTableViewCell
        let card: Card
        if indexPath.section == 0 {
            card = subject.visibleCards()[indexPath.item]
            cell.backgroundColor = UIColor.clear
            cell.togleVisibilityButton.setImage(UIImage(named: "Eye Visible"), for: UIControlState())
            cell.flashCardLabel.textColor = UIColor.white
            cell.flashCardLabel.alpha = 1.0
        }else{
            card = subject.hiddenCards()[indexPath.item]
            cell.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.1)
            cell.togleVisibilityButton.setImage(UIImage(named: "Eye Hidden"), for: UIControlState())
            cell.flashCardLabel.textColor = UIColor.black
            cell.flashCardLabel.alpha = 0.5
        }
        
        cell.card = card
        cell._flashCardsTableView = self
        let bgView = UIView()
            bgView.backgroundColor = UIColor.black
        
        cell.selectedBackgroundView = bgView
        
        cell.tintColor = UIColor.white
        cell.flashCardLabel.text = card.topic

        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if tableView.isEditing {
            return .none
        }
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let card = subject.cards[indexPath.item]
        subject.destroyCard(card)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let _card = sourceIndexPath.section == 0 ? subject.visibleCards()[sourceIndexPath.item] : subject.hiddenCards()[sourceIndexPath.item]
        _card.hidden = destinationIndexPath.section == 0 ? false : true
        _card.order = destinationIndexPath.item
        DataManager.current.saveSubjects()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let _card = indexPath.section == 0 ? subject.visibleCards()[indexPath.item] : subject.hiddenCards()[indexPath.item]
        let flashCardVC = self.storyboard?.instantiateViewController(withIdentifier: "flashCardVC") as! FlashCardViewController
            flashCardVC.card = _card
            flashCardVC.subject = subject
            flashCardVC.editMode = true
        self.present(flashCardVC, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: .default, title: "Trash") { action, indexPath in
            let card: Card
            if indexPath.section == 0 {
                card = self.subject.visibleCards()[indexPath.item]
            }else{
                card = self.subject.hiddenCards()[indexPath.item]
            }
            self.subject.destroyCard(card)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        deleteButton.backgroundColor = UIColor(red: 0.94, green: 0.63, blue: 0.34, alpha: 1)
        return [deleteButton]
    }
    
    func addCard() {
        
        if _stackVCDelegate.editMode == nil, let _subject = _stackVCDelegate.subject {
            DataManager.current.addSubject(_subject)
            _stackVCDelegate.editMode = true
        }
        
        let flashCardVC = self.storyboard?.instantiateViewController(withIdentifier: "flashCardVC") as! FlashCardViewController
        flashCardVC.subject = subject
        self.present(flashCardVC, animated: true, completion: nil)
    }
    
}

class FlashCardsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var flashCardLabel: UILabel!
    @IBOutlet weak var togleVisibilityButton: UIButton!
    
    var card: Card!
    weak var _flashCardsTableView: FlashCardsTableViewController!
    
    @IBAction func toggleVisibility(_ button: UIButton) {
        card.hidden == true ? card.subject.unHideCard(card) : card.subject.hideCard(card)
        _flashCardsTableView.tableView.reloadData()
    }
}
