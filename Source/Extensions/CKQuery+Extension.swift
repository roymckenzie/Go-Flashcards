//
//  CKQuery+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/2/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import CloudKit

// MARK:- CKQuery extension
extension CKQuery {
    
    /// Initialize a `CKQuery` with a `RecordType` enum value
    convenience init(recordType: RecordType, predicate: NSPredicate) {
        self.init(recordType: recordType.description, predicate: predicate)
    }
}
