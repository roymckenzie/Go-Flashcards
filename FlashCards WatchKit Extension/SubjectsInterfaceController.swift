//
//  SubjectsInterfaceController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/6/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import FlashCardsKit
import WatchKit
import Foundation

class SubjectsInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var subjectTable: WKInterfaceTable!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        reloadTable()
    }
    
    func reloadTable() {
        NSKeyedUnarchiver.setClass(Card.self, forClassName: "Card")
        NSKeyedUnarchiver.setClass(Subject.self, forClassName: "Subject")
        let subjects = User.sharedInstance().subjects
        subjectTable.setNumberOfRows(subjects.count, withRowType: "subjectRow")
        
        for (index, subject) in enumerate(subjects) {
            if let row = subjectTable.rowControllerAtIndex(index) as? SubjectRow {
                row.subjectLabel.setText(subject.name)
            }
        
        }
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        let subjectId = User.sharedInstance().subjects[rowIndex].id
        let context = [ "subjectId" : subjectId ]
        self.pushControllerWithName("flashCardsIC", context: context)
    }
    
}

class SubjectRow: NSObject {
    @IBOutlet weak var subjectLabel: WKInterfaceLabel!
    
}