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
        let notificationsEnabledPredicate = NSPredicate(format: "preferences.notificationEnabled == true")
        let stacks = realm.objects(Stack.self).filter(notificationsEnabledPredicate)
        
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
        notification.alertBody = "Practice makes perfect. It's time to review \(stack.name)."
        notification.fireDate = stack.notificationStartDate
        notification.userInfo = [
            "id": stack.id
        ]
        if let interval = stack.notificationInterval {
            notification.repeatInterval = interval
        }
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    static var appNotificationsEnabled: Bool {
        guard let types = UIApplication.shared.currentUserNotificationSettings?.types else { return false }
        if types.contains(.alert) {
            return true
        }
        return false
    }
    
    static func showEnableNotificationsAlert() {
        let controller = UIAlertController(title: "Notifications", message: "Notifications are disabled. Enable them in Settings.", preferredStyle: .alert)
        let notNowAction = UIAlertAction(title: "Not now", style: .destructive, handler: nil)
        controller.addAction(notNowAction)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let url = URL(string: UIApplicationOpenSettingsURLString) else { return }
            UIApplication.shared.openURL(url)
        }
        controller.addAction(settingsAction)
        UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.present(controller, animated: true, completion: nil)
    }
}

extension AppDelegate {
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if application.applicationState == .active { return }
        guard let identifier = notification.userInfo?["id"] as? String else { return }
        showViewFor(itemIdentifier: identifier, application: application)
    }
}
