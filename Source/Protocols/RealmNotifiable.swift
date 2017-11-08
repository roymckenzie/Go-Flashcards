//
//  RealmNotifiable.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/28/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation
import RealmSwift

protocol RealmNotifiable: class {
    func stopRealmNotification()
    func startRealmNotification(_ block: @escaping NotificationBlock)
    var realmNotificationToken: NotificationToken? { get set }
}

extension RealmNotifiable {
        
    func stopRealmNotification() {
        realmNotificationToken?.invalidate()
    }
    
    func startRealmNotification(_ block: @escaping NotificationBlock) {
        do {
            let realm = try Realm()
            realmNotificationToken = realm.observe(block)
        } catch {
            NSLog("Error setting up Realm Notification: \(error)")
        }
    }
}
