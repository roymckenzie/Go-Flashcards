//
//  CKRecord+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/27/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit

// MARK:- CKRecord extension
extension CKRecord {
    
    /// Initialize a `CKRecord` with a `RecordType` enum value
    convenience init(recordType: RecordType, zone: RecordZone) {
        self.init(recordType: recordType.description, zoneID: zone.zoneID)
    }
    
    /// Initialize a `CKRecord` with a `RecordType` enum value and Record ID
    convenience init(recordType: RecordType, recordID: CKRecordID) {
        self.init(recordType: recordType.rawValue, recordID: recordID)
    }
}
