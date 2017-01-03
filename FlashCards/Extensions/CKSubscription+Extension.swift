//
//  CKSubscription+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/2/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import CloudKit

// MARK:- CKQuery extension
extension CKSubscription {
    
    /// Initialize a `CKSubscription` with a `RecordType` enum value
    convenience init(recordType: RecordType, predicate: NSPredicate, options: CKSubscriptionOptions) {
        self.init(recordType: recordType.description, predicate: predicate, options: options)
    }
}

