//
//  Card.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/17/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation
import RealmSwift
import CloudKit
import UIKit

final class Card: Object {
    dynamic var frontText: String? = nil
    dynamic var frontImagePath: String? = nil
    dynamic var backText: String? = nil
    dynamic var backImagePath: String? = nil
    dynamic var mastered: Date? = nil
    dynamic var order: Double = 0
    let stacks = LinkingObjects(fromType: Stack.self, property: "cards")

    // CloudKitSyncable
    dynamic var id: String = UUID().uuidString
    dynamic var synced: Date? = nil
    dynamic var modified: Date = Date()
    dynamic var deleted: Date? = nil
    dynamic var recordChangeTag: String? = nil
    
    // Temporary for identifying Stack, is set to be ignored by Realm
    dynamic var stackReferenceName: String?
}

extension Card {
    
    private var documentsUrl: URL {
        return try! FileManager.default.url(for: .documentDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,create: false)
    }
    
    var frontImageUrl: URL? {
        guard let frontImagePath = frontImagePath else { return nil }
        return documentsUrl.appendingPathComponent(frontImagePath)
    }
    
    var backImageUrl: URL? {
        guard let backImagePath = backImagePath else { return nil }
        return documentsUrl.appendingPathComponent(backImagePath)
    }
    
    var frontImage: UIImage? {
        guard let url = frontImageUrl else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let image = UIImage(data: data)
            return image
        } catch {
            NSLog("Error fetching image from file system: \(error)")
            return nil
        }
    }
    
    var backImage: UIImage? {
        guard let url = backImageUrl else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let image = UIImage(data: data)
            return image
        } catch {
            NSLog("Error fetching image from file system: \(error)")
            return nil
        }
    }
}

// MARK:- Indexing and primary keys
extension Card {
    
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
        return ["stackReferenceName"]
    }
}

// MARK:- CloudKitSyncable
extension Card: CloudKitSyncable {
    
    var stack: Stack? {
        return stacks.first
    }
    
    var record: CKRecord {
        let record = CKRecord(recordType: .card, recordID: recordID)
        if let frontText = frontText {
            record.setObject(frontText as NSString, forKey: RecordType.Card.frontText.rawValue)
        }
        if let backText = backText {
            record.setObject(backText as NSString, forKey: RecordType.Card.backText.rawValue)
        }
        if let fileURL = frontImageUrl {
            record.setObject(CKAsset(fileURL: fileURL), forKey: RecordType.Card.frontImage.rawValue)
        }
        if let fileURL = backImageUrl {
            record.setObject(CKAsset(fileURL: fileURL), forKey: RecordType.Card.backImage.rawValue)
        }
        if let mastered = mastered {
            let masteredDate = NSDate(timeInterval: 0, since: mastered)
            record.setObject(masteredDate, forKey: RecordType.Card.mastered.rawValue)
        } else {
            record.setObject(nil, forKey: RecordType.Card.mastered.rawValue)
        }
        record.setObject(order as NSNumber, forKey: RecordType.Card.order.rawValue)
        if let reference = stack?.reference {
            record.setObject(reference, forKey: RecordType.Card.stack.rawValue)
        }
        return record
    }
}

// MARK:- CloudKitCodable
extension Card: CloudKitCodable {
    
    convenience init?(record: CKRecord) throws {
        self.init()
        let decoder = CloudKitDecoder(record: record)
        id              = decoder.recordName
        modified        = decoder.modified
        recordChangeTag = decoder.recordChangeTag
        frontText       = try? decoder.decode("frontText")
        frontImagePath  = try? decoder.decodeAsset("frontImage")
        backText        = try? decoder.decode("backText")
        backImagePath   = try? decoder.decodeAsset("backImage")
        mastered        = try? decoder.decode("mastered")
        order           = try decoder.decode("order")
        if let reference: CKReference = try decoder.decode("stack") {
           stackReferenceName = reference.recordID.recordName
        }
    }
}
