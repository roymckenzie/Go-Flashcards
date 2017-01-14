//
//  UserCardPreferences.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/7/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import RealmSwift
import CloudKit

//final class UserCardPreferences: Object {
//    dynamic var order: Double = 0
//    dynamic var mastered: Date? = nil
//    let cards = LinkingObjects(fromType: Card.self, property: "userCardPreferences")
//
//    
//    // CloudKitSyncable
//    dynamic var id: String = UUID().uuidString
//    dynamic var synced: Date? = nil
//    dynamic var modified: Date = Date()
//    dynamic var deleted: Date? = nil
//    dynamic var recordChangeTag: String? = nil
//    dynamic var recordOwnerName: String? = CKOwnerDefaultName
//    
//    // Temporary for identifying Card, is set to be ignored by Realm
//    dynamic var cardReferenceName: String?
//}
//
//// MARK:- Realm overrides
//extension UserCardPreferences {
//    
//    override open class func primaryKey() -> String? {
//        return "id"
//    }
//    
//    override open class func indexedProperties() -> [String] {
//        return [
//            "synced",
//            "modified"
//        ]
//    }
//    
//    override open class func ignoredProperties() -> [String] {
//        return [
//            "cardReferenceName"
//        ]
//    }
//}
//
//// MARK:- CloudKitSyncable
//extension UserCardPreferences: CloudKitSyncable {
//    typealias RecordZoneType = StackZone
//    
//    var card: Card {
//        return cards[0]
//    }
//    
//    var isSharedWithMe: Bool {
//        return false
//    }
//
//    var record: CKRecord {
//        let record = CKRecord(recordType: .userCardPreferences, recordID: recordID)
//        if let mastered = mastered {
//            let masteredDate = NSDate(timeInterval: 0, since: mastered)
//            record.setObject(masteredDate, forKey: RecordType.UserCardPreferences.mastered.rawValue)
//        } else {
//            record.setObject(nil, forKey: RecordType.UserCardPreferences.mastered.rawValue)
//        }
//        record.setObject(order as NSNumber, forKey: RecordType.UserCardPreferences.order.rawValue)
//        record.setObject(card.reference, forKey: RecordType.UserCardPreferences.card.rawValue)
//        return record
//    }
//}
//
//// MARK:- CloudKitCodable
//extension UserCardPreferences: CloudKitCodable {
//    
//    convenience init?(record: CKRecord) throws {
//        self.init()
//        let decoder = CloudKitDecoder(record: record)
//        self.id         = decoder.recordName
//        self.modified   = decoder.modified
//        self.recordChangeTag = decoder.recordChangeTag
//        self.recordOwnerName = decoder.recordOwnerName
//        self.order      = try decoder.decode("order")
//        self.mastered   = try? decoder.decode("mastered")
//        if let reference: CKReference = try decoder.decode("card") {
//            cardReferenceName = reference.recordID.recordName
//        }
//    }
//}
