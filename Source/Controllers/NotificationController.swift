//
//  NotificationController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 2/17/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift

private let Notifications = NSLocalizedString("Notifications", comment: "")
private let PracticeMakesPerfect = NSLocalizedString("Practice makes perfect. It's time to review %@.", comment: "")
private let NotificationsAreDisabled = NSLocalizedString("Notifications are disabled. Enable them in Settings.", comment: "")
private let NotNow = NSLocalizedString("Not now", comment: "")
private let Settings = NSLocalizedString("Settings", comment: "")

struct NotificationController {
    
    static func setStackNotifications() {
        let realm = try! Realm()
        let notificationsEnabledPredicate = NSPredicate(format: "preferences.notificationDate > %@", Date() as NSDate)
        let stacks = realm.objects(Stack.self).filter(notificationsEnabledPredicate)
        
        let expiredPredicate = NSPredicate(format: "preferences.notificationDate < %@", Date() as NSDate)
        let expiredNotificationStacks = stacks.filter(expiredPredicate)
        
        clearExpiredNotification(stacks: expiredNotificationStacks)
        clearAllNotifications()

        for stack in stacks {
            createNotification(stack)
        }
    }
    
    private static func clearAllNotifications() {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    private static func clearExpiredNotification(stacks: Results<Stack>) {
        if stacks.isEmpty { return }
        
        let realm = try! Realm()
        
        try? realm.write {
            stacks.setValue(nil, forKey: "preferences.notificationDate")
        }
    }
    
    private static func createNotification(_ stack: Stack) {
        let notification = UILocalNotification()
        notification.alertBody = String(format: PracticeMakesPerfect, stack.name)
        notification.fireDate = stack.notificationDate
        notification.userInfo = [
            "id": stack.id
        ]
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    static var appNotificationsEnabled: Bool {
        guard let types = UIApplication.shared.currentUserNotificationSettings?.types else { return false }
        if types.contains(.alert) {
            return true
        }
        return false
    }
    
    static func showEnableNotificationsAlert(in viewController: UIViewController) {
        let controller = UIAlertController(title: Notifications, message: NotificationsAreDisabled, preferredStyle: .alert)
        let notNowAction = UIAlertAction(title: NotNow, style: .destructive, handler: nil)
        controller.addAction(notNowAction)
        let settingsAction = UIAlertAction(title: Settings, style: .default) { _ in
            guard let url = URL(string: UIApplicationOpenSettingsURLString) else { return }
            UIApplication.shared.openURL(url)
        }
        controller.addAction(settingsAction)
        viewController.present(controller, animated: true, completion: nil)
    }
}

extension AppDelegate {
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if application.applicationState == .active { return }
        guard let identifier = notification.userInfo?["id"] as? String else { return }
        showViewFor(itemIdentifier: identifier, application: application)
    }
}
