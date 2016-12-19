//
//  StacksInterfaceController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/6/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import WatchKit
import Foundation

class StacksInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var stackTable: WKInterfaceTable!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        reloadTable()
    }
    
    func reloadTable() {
        NSKeyedUnarchiver.setClass(Card.self, forClassName: "Card")
        NSKeyedUnarchiver.setClass(Subject.self, forClassName: "Subject")
        DataManager.current.refreshSubjects()
        let subjects = DataManager.current.subjects
        stackTable.setNumberOfRows(subjects.count, withRowType: "stackRow")
        
        for (index, subject) in subjects.enumerated() {
            if let row = stackTable.rowController(at: index) as? StackRow {
                row.stackLabel.setText(" "+subject.name)
            }
        
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        DataManager.current.refreshSubjects()
        let subjectId = DataManager.current.subjects[rowIndex].id
        let context = [ "subjectId" : subjectId ]
        self.pushController(withName: "flashCardsIC", context: context)
    }
    
    override func willActivate() {
        super.willActivate()
        reloadTable()
    }
}

class StackRow: NSObject {
    @IBOutlet weak var stackLabel: WKInterfaceLabel!
    
}
