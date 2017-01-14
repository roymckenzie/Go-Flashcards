//
//  RecordZone.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/7/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import CloudKit

/// Maps to `CKDatabaseScope`
enum DatabaseScope: Int {
    case `public` = 1
    case `private` = 2
    case shared = 3
}

extension DatabaseScope: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .public:
            return "public"
        case .private:
            return "private"
        case .shared:
            return "shared"
        }
    }
}

protocol RecordZone: CustomStringConvertible {
    var databaseScope: DatabaseScope { get }
    init(databaseScope: DatabaseScope)
}

extension RecordZone {
    
    var description: String {
        return Self.description
    }
    
    static var description: String {
        return "\(Self.self)"
    }
    
    private var databaseZoneDescription: String {
        return databaseScope.description + description
    }
    
    var didSetupZone: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "DidSetup" + databaseZoneDescription)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "DidSetup" + databaseZoneDescription)
        }
    }
    
    static var zone: CKRecordZone {
        return CKRecordZone(zoneName: Self.description)
    }
    
    static var zoneID: CKRecordZoneID {
        return zone.zoneID
    }
    
    var database: CKDatabase? {
        switch databaseScope {
        case .public:
            return CKContainer.default().publicCloudDatabase
        case .private:
            return CKContainer.default().privateCloudDatabase
        case .shared:
            if #available(iOS 10.0, *) {
                return CKContainer.default().sharedCloudDatabase
            } else {
                return nil
            }
        }
    }
    
    var subscription: CKSubscription? {
        var subscription: CKSubscription? = nil
        switch databaseScope {
        case .public:
            break
        case .private:
            if #available(iOS 10.0, *) {
                subscription = CKRecordZoneSubscription(zoneID: Self.zoneID,
                                                        subscriptionID: subscriptionID)
            } else {
                subscription = CKSubscription(zoneID: Self.zoneID,
                                              subscriptionID: subscriptionID,
                                              options: CKSubscriptionOptions(rawValue: 0))
            }
            
        case .shared:
            if #available(iOS 10.0, *) {
                subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
            }
        }

        subscription?.notificationInfo = Self.notificationInfo
        return subscription
    }
    
    var subscriptionID: String {
        return databaseZoneDescription + "Subscription"
    }
    
    static var notificationInfo: CKNotificationInfo {
        let notification = CKNotificationInfo()
        notification.shouldSendContentAvailable = true
        return notification
    }
    
    var notificationName: Notification.Name {
        return Notification.Name(rawValue: databaseZoneDescription)
    }

    private var previousZoneServerChangeTokenKey: String {
        return description + "ChangeTokenKey"
    }
    
    var previousZoneServerChangeToken: CKServerChangeToken? {
        get {
            guard let data = UserDefaults.standard.data(forKey: previousZoneServerChangeTokenKey) else {
                return nil
            }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.set(nil, forKey: previousZoneServerChangeTokenKey)
                return
            }
            let data = NSKeyedArchiver.archivedData(withRootObject: newValue)
            UserDefaults.standard.set(data, forKey: previousZoneServerChangeTokenKey)
        }
    }
    
    private var previousSharedDatabaseServerChangeTokenKey: String {
        return databaseZoneDescription + "ChangeTokenKey"
    }
    
    var previousSharedDatabaseServerChangeToken: CKServerChangeToken? {
        get {
            guard let data = UserDefaults.standard.data(forKey: previousSharedDatabaseServerChangeTokenKey) else {
                return nil
            }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.set(nil, forKey: previousSharedDatabaseServerChangeTokenKey)
                return
            }
            let data = NSKeyedArchiver.archivedData(withRootObject: newValue)
            UserDefaults.standard.set(data, forKey: previousSharedDatabaseServerChangeTokenKey)
        }
    }
    
    static var `public`: Self {
        return Self(databaseScope: .public)
    }
    static var `private`: Self {
        return Self(databaseScope: .private)
    }
    static var shared: Self {
        return Self(databaseScope: .shared)
    }
}

@available(iOS 10.0, *)
extension RecordZone {
    
    var ckDatabaseScope: CKDatabaseScope {
        return CKDatabaseScope(rawValue: databaseScope.rawValue)!
    }
}

@available(iOS 10.0, *)
extension CKDatabase {
    
    var localScope: DatabaseScope {
        return DatabaseScope(rawValue: databaseScope.rawValue)!
    }
}
