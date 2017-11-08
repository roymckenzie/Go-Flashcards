//
//  StacksInterfaceController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/6/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class StacksInterfaceController: WKInterfaceController {
    
    var dataSource = [Dictionary<String, String>]() {
        didSet {
            updateLoadingLabel()
        }
    }

    @IBOutlet var loadingLabel: WKInterfaceLabel!
    @IBOutlet weak var stackTable: WKInterfaceTable!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let session = WCSession.default
        session.delegate = self
        session.activate()
        
        reloadTable()
    }
    
    private func updateLoadingLabel() {
        switch dataSource.count {
        case 0:
            loadingLabel.setHidden(false)
            loadingLabel.setText("There are no Stacks. Add a Stack on your iPhone.")
        default:
            loadingLabel.setHidden(true)
        }
    }
    
    func reloadTable() {

        stackTable.setNumberOfRows(dataSource.count, withRowType: "stackRow")
        
        for (index, stack) in dataSource.enumerated() {
            if let row = stackTable.rowController(at: index) as? StackRow {
                row.stackLabel.setText(" "+stack["name"]!)
            }
        
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let stackId = dataSource[rowIndex]["id"]
        let context = [ "stackId" : stackId ]
        self.pushController(withName: "flashCardsIC", context: context)
    }
    
    override func willActivate() {
        super.willActivate()
        requestStacks()
    }
    
    func requestStacks() {
        let session = WCSession.default
        session.delegate = self
        
        if #available(watchOSApplicationExtension 2.2, *) {
            if session.activationState != .activated { return }
        }
        
        let watchMessage = WatchMessage.requestStacks
        session.sendMessage(watchMessage.message, replyHandler: { [weak self] message in
            guard let stacksInfo = message[watchMessage.description] as? [Dictionary<String, String>] else { return }
            self?.dataSource = stacksInfo
            self?.reloadTable()
        }) { [weak self] error in
            self?.loadingLabel.setText(error.localizedDescription)
            print(error.localizedDescription)
        }
    }
}

extension StacksInterfaceController: WCSessionDelegate {
    
    @available(watchOSApplicationExtension 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        requestStacks()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print(message)
    }
}

class StackRow: NSObject {
    @IBOutlet weak var stackLabel: WKInterfaceLabel!
    
}

