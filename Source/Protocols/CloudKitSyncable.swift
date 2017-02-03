//
//  CloudKitSyncable.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/26/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation
import CloudKit

protocol CloudKitSyncable {
    associatedtype RecordZoneType: RecordZone
    
    var id: String { get }
    var recordID: CKRecordID { get }
    var synced: Date? { get }
    var modified: Date { get }
    var deleted: Date? { get }
    var record: CKRecord { get }
    var recordChangeTag: String? { get }
    var recordZoneType: RecordZoneType.Type { get }
    var recordOwnerName: String? { get }
}

extension CloudKitSyncable {
    
    var reference: CKReference {
        return CKReference(recordID: recordID, action: .deleteSelf)
    }
    
    var isSharedWithMe: Bool {
        return recordOwnerName != CKOwnerDefaultName
    }
    
    var recordZoneType: RecordZoneType.Type {
        return RecordZoneType.self
    }
    
    var recordID: CKRecordID {
        if isSharedWithMe,
            let recordOwnerName = recordOwnerName {
            let zoneID = CKRecordZoneID(zoneName: recordZoneType.description, ownerName: recordOwnerName)
            return CKRecordID(recordName: id, zoneID: zoneID)
        }
        return CKRecordID(recordName: id, zoneID: recordZoneType.zoneID)
    }
    
    func recordIDWith(_ parentRecord: CKRecord) -> CKRecordID {
        return CKRecordID(recordName: id, zoneID: parentRecord.recordID.zoneID)
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
    
    func assetForUrl(fileURL: URL) -> CKAsset {
        return CKAsset(fileURL: fileURL)
    }
}
