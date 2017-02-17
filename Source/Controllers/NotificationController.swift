//
//  NotificationController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 2/17/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift

struct NotificationController {
    
    static func setStackNotifications() {
        let realm = try! Realm()
        let stacks = realm.objects(Stack.self)
        
        clearAllNotifications()
        for stack in stacks {
            createNotification(stack)
        }
    }
    
    static func clearAllNotifications() {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    private static func createNotification(_ stack: Stack) {
        let notification = UILocalNotification()
        notification.alertBody = "Hi! Practice makes perfect. It's time to review \(stack.name)."
        notification.fireDate = Date(timeIntervalSinceNow: 10)
        notification.userInfo = [
            "id": stack.id
        ]
        notification.repeatInterval = .minute
        UIApplication.shared.scheduleLocalNotification(notification)
    }
}

extension AppDelegate {
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if application.applicationState == .active { return }
        guard let identifier = notification.userInfo?["id"] as? String else { return }
        showViewFor(itemIdentifier: identifier, application: application)
    }
}
