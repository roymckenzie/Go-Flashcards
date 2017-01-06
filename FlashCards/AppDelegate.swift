//
//  AppDelegate.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import CloudKit
import RealmSwift
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        Fabric.with([Crashlytics()])
        registerForNotifications(application: application)
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 3,
            migrationBlock: { migration, oldSchemaVersion in

        })
        RealmMigrator.runMigration()

        CloudKitController.checkAccountStatus()
            .then { available in
                if available {
                    CloudKitController.setupStackZone()
                    CloudKitSyncManager.current.setupNotifications()
                    CloudKitSyncManager.current.runSync()
                }
            }
        
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        let subscriptionNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        NotificationCenter.default.post(name: .stackZoneUpdated, object: subscriptionNotification)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension AppDelegate: WCSessionDelegate {
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        let realm = try! Realm()
        
        switch message.keys.first! {
        case WatchMessage.requestStacks.description:
            let stacks = Array(realm.objects(Stack.self))
            let reply = WatchMessage.requestStacks.reply(object: stacks)
            replyHandler(reply)
        case "requestCards":
            guard let stackId = message["requestCards"] as? String else { return }
            guard let stack = realm.object(ofType: Stack.self, forPrimaryKey: stackId) else { return }
            let reply = WatchMessage.requestCards(stackId: stackId).reply(object: Array(stack.unmasteredCards))
            replyHandler(reply)
        case "masterCard":
            guard let cardId = message["masterCard"] as? String else { return }
            guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return }
            try? realm.write {
                card.mastered = Date()
            }
            let reply = WatchMessage.masterCard(cardId: cardId).reply(object: true)
            replyHandler(reply)
        default:
            break
        }
    }
}

import UserNotifications

extension AppDelegate {
    
    func registerForNotifications(application: UIApplication) {
        
        if #available(iOS 10.0, *) {
            
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { success, error in
                
                if let error = error {
                    NSLog("Error registering for notifications: \(error)")
                }
                
                if success {
                    NSLog("Successfully registered for notifications")
                    application.registerForRemoteNotifications()
                }
            }
            
        } else {
            
            let settings = UIUserNotificationSettings(types: [.alert], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        

    }
}
