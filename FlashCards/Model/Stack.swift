//
//  Stack.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/23/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit
import RealmSwift

final class Stack: Object {
    dynamic var name: String = ""
    let cards = List<Card>()
    
    // CloudKitSyncable
    dynamic var id: String = UUID().uuidString
    dynamic var synced: Date? = nil
    dynamic var modified: Date = Date()
    dynamic var deleted: Date? = nil
    dynamic var recordChangeTag: String? = nil
}

// MARK:- CloudKitSyncable
extension Stack: CloudKitSyncable {
    
    var reference: CKReference {
        return CKReference(recordID: recordID, action: .deleteSelf)
    }
    
    var record: CKRecord {
        let record = CKRecord(recordType: .stack, recordID: recordID)
        record.setObject(name as NSString, forKey: RecordType.Stack.name.rawValue)
        return record
    }
    
    private var undeletedCards: Results<Card> {
        let predicate = NSPredicate(format: "deleted == nil")
        return cards.filter(predicate)
    }
    
    var sortedCards: Results<Card> {
        return undeletedCards.sorted(byProperty: "order")
    }
    
    var masteredCards: Results<Card> {
        let predicate = NSPredicate(format: "mastered != nil")
        return sortedCards.filter(predicate)
    }

    var unmasteredCards: Results<Card> {
        let predicate = NSPredicate(format: "mastered == nil")
        return sortedCards.filter(predicate)
    }
}

// MARK:- CloudKitCodable
extension Stack: CloudKitCodable {
    
    convenience init?(record: CKRecord) throws {
        self.init()
        let decoder = CloudKitDecoder(record: record)
        id              = decoder.recordName
        modified        = decoder.modified
        recordChangeTag = decoder.recordChangeTag
        name            = try decoder.decode("name")
    }
}

// MARK:- Indexing and primary keys
extension Stack {
    
    override open class func primaryKey() -> String? {
        return "id"
    }
    
    override open class func indexedProperties() -> [String] {
        return [
            "synced",
            "modified"
        ]
    }
}

// MARK:- View model
extension Stack {
    
    /// A string representing the amount of cards
    /// "1 card", "No cards", etc.
    var cardCountString: String {
        let count = sortedCards.count
        let stringCount = count > 0 ? "\(count)" : "No"
        var pluralityTypeString = "cards"
        if count == 1 {
            pluralityTypeString = "card"
        }
        return "\(stringCount) \(pluralityTypeString)"
    }
    
    var progressDescription: String {
        
        let detailText: String
        
        switch (unmasteredCards.count, masteredCards.count) {
        case (0, 0):
            detailText = "No cards"
        case (0, let masteredCount) where masteredCount > 0:
            detailText = "All cards mastered"
        case (let unmasteredCount, 0) where unmasteredCount > 0:
            detailText = "\(cardTextPlurality(unmasteredCount)) to review"
        case (let unmasteredCount, let masteredCount) where unmasteredCount > 0 && masteredCount > 0:
            detailText = "\(masteredCount) of \(cardTextPlurality(cards.count)) mastered"
        default:
            detailText = ""
        }
        
        return detailText
    }
    
    func cardTextPlurality(_ count: Int) -> String {
        switch count {
        case 0: return "No cards"
        case 1: return "One card"
        default: return "\(count) cards"
        }
    }
}
