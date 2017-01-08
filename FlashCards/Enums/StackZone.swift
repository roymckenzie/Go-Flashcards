//
//  StackZone.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/7/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import CloudKit

struct StackZone: RecordZone {
    let databaseScope: DatabaseScope
    init(databaseScope: DatabaseScope) {
        self.databaseScope = databaseScope
    }
}

extension StackZone {
    
    var subscription: CKSubscription? {
        let subscription: CKSubscription?
        
        switch databaseScope {
        case .public:
            return nil
        case .private:
            if #available(iOS 10.0, *) {
                subscription = CKRecordZoneSubscription(zoneID: StackZone.zoneID,
                                                        subscriptionID: subscriptionID)
            } else {
                subscription = CKSubscription(zoneID: StackZone.zoneID,
                                              subscriptionID: subscriptionID,
                                              options: CKSubscriptionOptions(rawValue: 0))
            }
        case .shared:
            if #available(iOS 10.0, *) {
                subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
            } else {
                subscription = nil
            }
        }
        
        subscription?.notificationInfo = StackZone.notificationInfo
        
        return subscription
    }
}
