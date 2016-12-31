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

private let DidSetupStackZoneKey = "DidSetupStackZoneKey"
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
    
    static let current: CloudKitController = CloudKitController()
    
    init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
}

extension CloudKitController {
    
    public static func checkCurrentNotificationSubscriptions() {

        CKContainer.default()
            .privateCloudDatabase
            .fetchAllSubscriptions { subscriptions, error in
                
                if let error = error {
                    print("Could not fetch current subscriptions: \(error)")
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
                    print("Could not fetch current subscriptions: \(error)")
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
                print("Could not save stacks subscription notification: \(error)")
            }
            
            if let subscriptionID = subscriptions?.first?.subscriptionID {
                print("Saved subscription notification: \(subscriptionID)")
            }
        }
        
        CKContainer.default()
            .privateCloudDatabase
            .add(operation)
    }
    
    public func getStacks() -> Promise<[Stack]> {
        let promise = Promise<[Stack]>()
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: .stack, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: RecordZone.stackZone.zoneID) { records, error in
            
            if let error = error {
                promise.reject(error)
            }
            
            if let records = records {
                do {
//                    let stacks = try records.flatMap(Stack.init)
//                    promise.fulfill(stacks)
                } catch {
                    promise.reject(error)
                }
            } else {
                promise.fulfill([])
            }
        }
        
        return promise
    }
    
    public func getCardsFromStack(record: CKRecord) -> Promise<[Card]> {
        let promise = Promise<[Card]>()
        
//        let reference = CKReference(record: record, action: .none)
//        let predicate = NSPredicate(format: "stack == %@", reference)
//        let query = CKQuery(recordType: .card, predicate: predicate)
//        
//        privateDB.perform(query, inZoneWith: RecordZone.stackZone.zoneID) { records, error in
//            
//            if let error = error {
//                promise.reject(error)
//            }
//            
//            if let records = records {
//                do {
//                    let stacks = try records.flatMap(Card.init)
//                    promise.fulfill(stacks)
//                } catch {
//                    promise.reject(error)
//                }
//            } else {
//                promise.fulfill([])
//            }
//        }
        
        return promise
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
                    print("Error creating zone: \(error)")
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

// MARK:- CKQuery extension
extension CKQuery {
    
    /// Initialize a `CKQuery` with a `RecordType` enum value
    convenience init(recordType: RecordType, predicate: NSPredicate) {
        self.init(recordType: recordType.description, predicate: predicate)
    }
}

// MARK:- CKQuery extension
extension CKSubscription {
    
    /// Initialize a `CKSubscription` with a `RecordType` enum value
    convenience init(recordType: RecordType, predicate: NSPredicate, options: CKSubscriptionOptions) {
        self.init(recordType: recordType.description, predicate: predicate, options: options)
    }
}
