//
//  StackPreferences.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/11/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import Foundation
import CloudKit
import RealmSwift

final class StackPreferences: Object {
    let stacks = LinkingObjects(fromType: Stack.self, property: "preferences")

    // Temp for decoding a CKRecord
    dynamic var stackReferenceName: String?
    dynamic var tempOrderedJSON = ""
    dynamic var tempMasteredJSON = ""
    dynamic var notificationDate: Date?

    // CloudKitSyncable
    dynamic var id: String = UUID().uuidString
    dynamic var synced: Date? = nil
    dynamic var modified: Date = Date()
    dynamic var deleted: Date? = nil
    dynamic var recordChangeTag: String? = nil
    dynamic var recordOwnerName: String? = CKOwnerDefaultName
}

extension StackPreferences {
    
    convenience init(stack: Stack) {
        self.init()
        self.id = "\(stack.id)_preferences"
    }
    
    override open class func primaryKey() -> String? {
        return "id"
    }
    
    override open class func indexedProperties() -> [String] {
        return [
            "synced",
            "modified"
        ]
    }
    
    override open class func ignoredProperties() -> [String] {
        return [
            "stackReferenceName",
            "tempOrderedJSON",
            "tempMasteredJSON"
        ]
    }
}

extension StackPreferences: CloudKitSyncable {
    typealias RecordZoneType = StackZone
    
    var record: CKRecord {
        let record = CKRecord(recordType: .stackPreferences, recordID: recordID)
        record.setObject(orderedJSONString as NSString, forKey: RecordType.StackPreferences.orderedJSON.rawValue)
        record.setObject(masteredJSONString as NSString, forKey: RecordType.StackPreferences.masteredJSON.rawValue)
        record.setObject(notificationDate as NSDate?, forKey: RecordType.StackPreferences.notificationDate.rawValue)
        record.setObject(stack!.reference, forKey: RecordType.StackPreferences.stack.rawValue)
        return record
    }
}

extension StackPreferences {
        
    // MARK:- For encoding to server
    var stack: Stack? {
        return stacks.first
    }
    
    var cards: List<Card> {
        return stacks.first!.cards
    }
    
    private var orderedJSONData: Data {
        var orderedDic = [String: Float]()
        for card in cards {
            orderedDic[card.id] = card.order
        }
        return try! JSONSerialization.data(withJSONObject: orderedDic, options: .prettyPrinted)
    }
    
    private var masteredJSONData: Data {
        var masteredDic = [String: TimeInterval?]()
        for card in cards {
            masteredDic.updateValue(card.mastered?.timeIntervalSince1970, forKey: card.id)
        }
        return try! JSONSerialization.data(withJSONObject: masteredDic, options: .prettyPrinted)
    }
    
    fileprivate var orderedJSONString: String {
        return String(data: orderedJSONData, encoding: .utf8)!
    }
    
    fileprivate var masteredJSONString: String {
        return String(data: masteredJSONData, encoding: .utf8)!
    }
    
    var ordered: [String: Float] {
        guard let orderedData = tempOrderedJSON.data(using: .utf8) else { return [:] }
        guard let ordered = try? JSONSerialization.jsonObject(with: orderedData, options: .allowFragments) as? [String: Float] else { return [:] }
        return ordered ?? [:]
    }
    
    var mastered: [String: TimeInterval?] {
        guard let masteredData = tempMasteredJSON.data(using: .utf8) else { return [:] }
        guard let mastered = try? JSONSerialization.jsonObject(with: masteredData, options: .allowFragments) as? [String: TimeInterval?] else { return [:] }
        return mastered ?? [:]
    }
}

extension StackPreferences: CloudKitCodable {

    convenience init?(record: CKRecord) throws {
        self.init()
        let decoder = CloudKitDecoder(record: record)
        id              = decoder.recordName
        modified        = decoder.modified
        recordChangeTag = decoder.recordChangeTag
        recordOwnerName = decoder.recordOwnerName
        tempOrderedJSON = try decoder.decode("orderedJSON")
        tempMasteredJSON = try decoder.decode("masteredJSON")
        notificationDate = try? decoder.decode("notificationDate")
        
        if let reference: CKReference = try decoder.decode("stack") {
            stackReferenceName = reference.recordID.recordName
        }
    }
}
