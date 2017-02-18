
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
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        #if RELEASE
            Fabric.with([Crashlytics()])
        #endif
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")

        let languageCode = Locale.autoupdatingCurrent.languageCode
        Crashlytics.sharedInstance().setObjectValue(languageCode, forKey: "languageCode")
        
        registerForNotifications(application: application)
        runRealmMigration()
        runAppDelegateSync()
        
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        
        NotificationController.setStackNotifications()
                        
        return true
    }
    
    @available(iOS 10.0, *)
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShareMetadata) {
        
        var name: String = "Unknown User"
        if let firstName = cloudKitShareMetadata.ownerIdentity.nameComponents?.givenName {
            name = firstName
        }
        
        var stackName = "a Stack"
        if let sharedStackName = cloudKitShareMetadata.share[CKShareTitleKey] as? String {
            stackName += "\n\"\(sharedStackName)\"\n"
        }
        let alert = UIAlertController(title: "\(name) shared \(stackName) with you.", message: "Would you like to collaborate with \(name) on this Stack or make a personal copy for yourself?", preferredStyle: .alert)
        
        let collaborateAction = UIAlertAction(title: "Collaborate", style: .default) { [weak self] _ in
            self?.collaborateStack(with: cloudKitShareMetadata)
        }
        alert.addAction(collaborateAction)
        
        let copyAction = UIAlertAction(title: "Copy", style: .default) { [weak self] _ in
            self?.copyStack(with: cloudKitShareMetadata)
        }
        alert.addAction(copyAction)
        
        let cancelAction = UIAlertAction(title: "Ignore", style: .default, handler: nil)
        alert.addAction(cancelAction)
        
        UIApplication.shared.delegate?.window??.rootViewController?.present(alert, animated: true, completion: nil)
        
        return 

    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        CoreSpotlightController.reindex()
    }
    
    @available(iOS 10.0, *)
    private func copyStack(with shareMetadata: CKShareMetadata) {
        lv.show(withMessage: "Copying Stack")
        CloudKitController.acceptShares(with: [shareMetadata])
            .then {
                CloudKitSyncManager.current.pauseSyncing()
                return self.fetchStackAndCopy(with: shareMetadata.rootRecordID)
            }
            .then {
                return self.delete(shareMetadata.share)
            }
            .then {
                self.lv.hide()
                CloudKitSyncManager.current.resumeSyncing()
                CloudKitSyncManager.current.runSync()
            }
            .catch { error in
                print("Could not accept share")
            }
    }
    
    let lv = LoadingView(labelText: "Loading...")
    
    @available(iOS 10.0, *)
    private func collaborateStack(with shareMetadata: CKShareMetadata) {
        lv.show(withMessage: "Loading Stack")
        CloudKitController.acceptShares(with: [shareMetadata])
            .then {
                return CloudKitSyncManager.current.runSync()
            }
            .then {
                self.lv.hide()
            }
            .catch { error in
                print("Could not accept share")
            }
        
    }
    
    enum CardCopyError: Error {
        case stackRecordNil
    }
    @available(iOS 10.0, *)
    private func fetchStackAndCopy(with recordID: CKRecordID) -> Promise<Void> {
        let promise = Promise<Void>()
        CKContainer.default()
            .sharedCloudDatabase
            .fetch(withRecordID: recordID) { record, error in
            
            if let error = error {
                promise.reject(error)
                return
            }
            
            if let stackRecord = record {

                let predicate = NSPredicate(format: "stack == %@", stackRecord)
                let query = CKQuery(recordType: .card, predicate: predicate)
                CKContainer.default().sharedCloudDatabase.perform(query, inZoneWith: stackRecord.recordID.zoneID) { cardRecords, error in
                    
                    if let error = error {
                        promise.reject(error)
                        return
                    }
                    
                    var recordsToSave = [stackRecord]
                    if let cardRecords = cardRecords {
                        recordsToSave.append(contentsOf: cardRecords)
                    }
                    
                    CloudKitSyncManager.current.save(recordsToSave, makeCopy: true)
                    promise.fulfill()
                }
            }
            
        }
        return promise
    }
    
    @available(iOS 10.0, *)
    private func delete(_ share: CKShare) {
        CKContainer
            .default()
            .sharedCloudDatabase
            .delete(withRecordID: share.recordID) {  _, error in
                
                if let error = error {
                    print("Could not delete share: \(error)")
                    return
                }
 
            }

    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        let subscriptionNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
        guard let subscriptionID = subscriptionNotification.subscriptionID else {
            print("Received a remote notification for unknown subscriptionID")
            return
        }
        
        switch subscriptionID {
        case StackZone.private.subscriptionID:
            NotificationCenter.default.post(name: StackZone.private.notificationName, object: subscriptionNotification)
        case StackZone.shared.subscriptionID:
            NotificationCenter.default.post(name: StackZone.shared.notificationName, object: subscriptionNotification)
        default:
            break
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        CloudKitSyncManager.current.runSync()
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
            let undeletedPredicate = NSPredicate(format: "deleted == nil")
            let stacks = realm.objects(Stack.self).filter(undeletedPredicate).filter(undeletedPredicate)
            let reply = WatchMessage.requestStacks.reply(object: Array(stacks))
            replyHandler(reply)
        case "requestCards":
            guard let stackId = message["requestCards"] as? String else { return }
            guard let stack = realm.object(ofType: Stack.self, forPrimaryKey: stackId) else { return }
            let reply = WatchMessage.requestCards(stackId: stackId).reply(object: Array(stack.unmasteredCards))
            replyHandler(reply)
        case "requestCard":
            guard let cardId = message["requestCard"] as? String else { return }
            guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return }
            let reply = WatchMessage.requestCard(cardId: cardId).reply(object: card)
            replyHandler(reply)
        case "masterCard":
            guard let cardId = message["masterCard"] as? String else { return }
            guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return }
            try? realm.write {
                card.mastered = Date()
                card.stack?.preferences?.modified = Date()
            }
            let reply = WatchMessage.masterCard(cardId: cardId).reply(object: true)
            replyHandler(reply)
        default:
            break
        }
    }
}

extension AppDelegate {
    
    func registerForNotifications(application: UIApplication) {
        
        if #available(iOS 10.0, *) {
            
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { success, error in
                
                if let error = error {
                    print("Error registering for notifications: \(error)")
                }
                
                if success {
                    print("Successfully registered for notifications")
                    application.registerForRemoteNotifications()
                }
            }
            
        } else {
            
            let settings = UIUserNotificationSettings(types: [.alert], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
    }
    
    func runRealmMigration() {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 2,
            migrationBlock: { migration, oldSchemaVersion in
                
        })
        RealmMigrator.runMigration()
    }
    
    func runAppDelegateSync() {
        CloudKitController
            .checkAccountStatus()
            .then { available in
                if !available { return }
                CloudKitController
                    .setup(StackZone.private)
                    .then {
                        return CloudKitController.checkCloudKitSubscriptions()
                    }
                    .then {
                        CloudKitSyncManager.current.setupNotifications()
                        CloudKitSyncManager.current.runSync()
                    }
        }
    }
}
