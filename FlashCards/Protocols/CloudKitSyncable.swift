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
    var id: String { get }
    var recordID: CKRecordID { get }
    var synced: Date? { get }
    var modified: Date { get }
    var deleted: Date? { get }
    var record: CKRecord { get }
    var recordChangeTag: String? { get }
}

extension CloudKitSyncable {
    
    var recordID: CKRecordID {
        return CKRecordID(recordName: id, zoneID: RecordZone.stackZone.zoneID)
    }
    
    var needsSave: Bool {
        if needsDelete { return false }
        guard let synced = synced else {
            return true
        }
        return synced < modified
    }
    
    var needsDelete: Bool {
        return deleted != nil
    }
    
    func assetForUrl(fileURL: URL) -> CKAsset {
        return CKAsset(fileURL: fileURL)
    }
}
