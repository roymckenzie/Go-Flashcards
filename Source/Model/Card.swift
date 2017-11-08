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
    @objc dynamic var frontText: String? = nil
    @objc dynamic var frontImagePath: String? = nil
    @objc dynamic var backText: String? = nil
    @objc dynamic var backImagePath: String? = nil
    @objc dynamic var order: Float = 0
    @objc dynamic var mastered: Date?
    let stacks = LinkingObjects(fromType: Stack.self, property: "cards")

    // CloudKitSyncable
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var synced: Date? = nil
    @objc dynamic var modified: Date = Date()
    @objc dynamic var deleted: Date? = nil
    @objc dynamic var recordChangeTag: String? = nil
    @objc dynamic var recordOwnerName: String? = CKOwnerDefaultName
    
    // Temporary for identifying Stack, is set to be ignored by Realm
    @objc dynamic var stackReferenceName: String?
    
    // Temporary for seeing if image was updated so we 
    // aren't constantly saving same image to server
    @objc dynamic var frontImageUpdated: Bool = false
    @objc dynamic var backImageUpdated: Bool = false
    
    // MARK:- Indexing and primary keys
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
            "frontImageUpdated",
            "backImageUpdated"
        ]
    }
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

// MARK:- CloudKitSyncable
extension Card: CloudKitSyncable {
    typealias RecordZoneType = StackZone
    
    var stack: Stack? {
        return stacks.first
    }
    
    var isParentSharedWithMe: Bool {
        if #available(iOS 10.0, *) {
            return stack?.recordOwnerName != CKCurrentUserDefaultName
        } else {
            return false
        }
    }
    
    var isSharedWithMe: Bool {
        return isParentSharedWithMe
    }
    
    var needsPrivateSave: Bool {
        if needsPrivateDelete { return false }
        if isSharedWithMe { return false }
        guard let synced = synced else {
            return true
        }
        return synced < modified
    }
    
    var needsPrivateDelete: Bool {
        if isSharedWithMe { return false }
        return deleted != nil
    }
    
    var needsSharedSave: Bool {
        if !isSharedWithMe { return false }
        if needsSharedDelete { return false }
        guard let synced = synced else {
            return true
        }
        return synced < modified
    }
    
    var needsSharedDelete: Bool {
        if !isSharedWithMe { return false }
        return deleted != nil
    }
    
    var record: CKRecord {
        let record = CKRecord(recordType: .card, recordID: recordIDWith(stack!.record))
        
        if let frontText = frontText {
            record.setObject(frontText as NSString, forKey: RecordType.Card.frontText.rawValue)
        }
        if let backText = backText {
            record.setObject(backText as NSString, forKey: RecordType.Card.backText.rawValue)
        }
        if let fileURL = frontImageUrl {
            if frontImageUpdated {
                record.setObject(CKAsset(fileURL: fileURL), forKey: RecordType.Card.frontImage.rawValue)
            }
        } else {
            record.setObject(nil, forKey: RecordType.Card.frontImage.rawValue)
        }
        if let fileURL = backImageUrl {
            if backImageUpdated {
                record.setObject(CKAsset(fileURL: fileURL), forKey: RecordType.Card.backImage.rawValue)
            }
        } else {
            record.setObject(nil, forKey: RecordType.Card.backImage.rawValue)
        }
        record.setObject(stack!.reference, forKey: RecordType.Card.stack.rawValue)
        if #available(iOS 10.0, *) {
            record.setParent(stack!.recordID)
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
        recordOwnerName = decoder.recordOwnerName
        frontText       = try? decoder.decode("frontText")
        frontImagePath  = try? decoder.decodeAsset("frontImage")
        backText        = try? decoder.decode("backText")
        backImagePath   = try? decoder.decodeAsset("backImage")
        if let reference: CKReference = try decoder.decode("stack") {
           stackReferenceName = reference.recordID.recordName
        }
    }
}

// MARK:- Initialize card from QuizletCard
extension Card {
    
    convenience init(card: QuizletCard) {
        self.init()
        self.frontText = card.frontText
        self.backText = card.backText
        self.backImagePath = card.localImagePath
        self.backImageUpdated = true
    }
}
