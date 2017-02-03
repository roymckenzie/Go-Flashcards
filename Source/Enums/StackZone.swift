//
//  StackZone.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/7/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import CloudKit

struct StackZone: RecordZone {
    let databaseScope: DatabaseScope
    init(databaseScope: DatabaseScope) {
        self.databaseScope = databaseScope
    }
}
