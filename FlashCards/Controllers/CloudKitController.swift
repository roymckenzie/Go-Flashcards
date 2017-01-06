//
//  CloudKitController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/18/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit

extension RecordZone {
    
    var subscription: CKSubscription {
        let subscription: CKSubscription
        
        if #available(iOS 10.0, *) {
            subscription = CKRecordZoneSubscription(zoneID: zoneID,
                                            subscriptionID: subscriptionID)
        } else {
            subscription = CKSubscription(zoneID: zoneID,
                                  subscriptionID: subscriptionID,
                                  options: CKSubscriptionOptions(rawValue: 0))
        }
        
        subscription.notificationInfo = notificationInfo
        
        return subscription
    }
    
    var notificationInfo: CKNotificationInfo {
        let notification = CKNotificationInfo()
        notification.shouldSendContentAvailable = true
        return notification
    }
    
    var subscriptionID: String {
        return self.description + "Subscription"
    }
}
enum NotificationType: String {
    case stackUpdated
}

extension Notification.Name {
    
    static var stackZoneUpdated: Notification.Name {
        return Notification.Name(rawValue: "StackZoneUpdated")
    }
}

enum CloudKitControllerError: Error {
    case iCloudAccountNotAvailable
}

private let DidSetupStackZoneKey = "DidSetupStackZoneKey"
private let ICloudAccountAvailable = "ICloudAccountAvailable"

/// CloudKit database access controller
struct CloudKitController {
    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase
    
    private static var userDefaults: UserDefaults {
        return .standard
    }
    
    fileprivate static var didSetupStackZone: Bool {
        get {
            return userDefaults.bool(forKey: DidSetupStackZoneKey)
        }
        set {
            userDefaults.set(newValue, forKey: DidSetupStackZoneKey)
        }
    }
    
    static var iCloudAccountAvailable: Bool {
        get {
            return userDefaults.bool(forKey: ICloudAccountAvailable)
        }
        set {
            userDefaults.set(newValue, forKey: ICloudAccountAvailable)
        }
    }
    
    static let current: CloudKitController = CloudKitController()
    
    init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
}

extension CloudKitController {
    
    @discardableResult
    public static func checkAccountStatus() -> Promise<Bool> {
        return Promise<Bool>(work: { fulfill, reject in
            CKContainer.default().accountStatus() { status, error in
                switch status {
                case .available:
                    fulfill(true)
                case .noAccount, .restricted, .couldNotDetermine:
                    reject(CloudKitControllerError.iCloudAccountNotAvailable)
                }
            }
        })
    }
    
    public static func checkCurrentNotificationSubscriptions() {

        CKContainer.default()
            .privateCloudDatabase
            .fetchAllSubscriptions { subscriptions, error in
                
                if let error = error {
                    NSLog("Could not fetch current subscriptions: \(error)")
                }
                
                if let subscriptions = subscriptions {
                    if let _ = subscriptions.first(where: {
                        $0.subscriptionID == RecordZone.stackZone.subscriptionID
                    }) {
                    } else {
                        subscribeToStackZoneNotifications()
                    }
                }
        }
    }
    
    public static func clearNotifications() {
        CKContainer.default()
            .privateCloudDatabase
            .fetchAllSubscriptions { subscriptions, error in
                
                if let error = error {
                    NSLog("Could not fetch current subscriptions: \(error)")
                }
                
                if let subscriptions = subscriptions {
                    subscriptions.forEach { subscription in
                        CKContainer.default().privateCloudDatabase
                            .delete(withSubscriptionID: subscription.subscriptionID, completionHandler: { id, error in
                                if let error = error {
                                    NSLog("Could not delete subscription: \(error)")
                                }
                                
                                if let subscriptionId = id {
                                    NSLog("Deleted subscription id: \(subscriptionId)")
                                }
                            })
                    }
                }
        }
    }
    
    public static func subscribeToStackZoneNotifications() {
    
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [RecordZone.stackZone.subscription],
                                                       subscriptionIDsToDelete: nil)
        
        operation.modifySubscriptionsCompletionBlock = { subscriptions, _ , error in
            
            if let error = error {
                NSLog("Could not save stacks subscription notification: \(error)")
            }
            
            if let subscriptionID = subscriptions?.first?.subscriptionID {
                NSLog("Saved subscription notification: \(subscriptionID)")
            }
        }
        
        CKContainer.default()
            .privateCloudDatabase
            .add(operation)
    }
        
    @discardableResult
    public static func setupStackZone() -> Promise<CloudKitController> {
        let promise = Promise<CloudKitController>()
        
        if didSetupStackZone {
            promise.fulfill(current)
            return promise
        }
        
        CKContainer.default()
            .privateCloudDatabase
            .save(RecordZone.stackZone.zone) { recordZone, error in

                if let error = error {
                    NSLog("Error creating zone: \(error)")
                    promise.reject(error)
                }
                
                if let _ = recordZone {
                    didSetupStackZone = true
                    promise.fulfill(current)
                }
            }
        
        return promise
    }
}
