//
//  StacksInterfaceController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/6/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import FlashCardsKit
import WatchKit
import Foundation

class StacksInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var stackTable: WKInterfaceTable!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        reloadTable()
    }
    
    func reloadTable() {
        NSKeyedUnarchiver.setClass(Card.self, forClassName: "Card")
        NSKeyedUnarchiver.setClass(Subject.self, forClassName: "Subject")
        User.sharedInstance().refreshSubjects()
        let subjects = User.sharedInstance().subjects
        stackTable.setNumberOfRows(subjects.count, withRowType: "stackRow")
        
        for (index, subject) in enumerate(subjects) {
            if let row = stackTable.rowControllerAtIndex(index) as? StackRow {
                row.stackLabel.setText(" "+subject.name)
            }
        
        }
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        User.sharedInstance().refreshSubjects()
        let subjectId = User.sharedInstance().subjects[rowIndex].id
        let context = [ "subjectId" : subjectId ]
        self.pushControllerWithName("flashCardsIC", context: context)
    }
    
    override func willActivate() {
        super.willActivate()
        reloadTable()
    }
}

class StackRow: NSObject {
    @IBOutlet weak var stackLabel: WKInterfaceLabel!
    
}