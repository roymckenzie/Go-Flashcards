//
//  RecordZone.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/26/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation
import CloudKit

enum RecordZone: String {
    case stackZone
}

extension RecordZone: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .stackZone:
            return "StackZone"
        }
    }
    
    var zone: CKRecordZone {
        return CKRecordZone(zoneName: self.description)
    }
    
    var zoneID: CKRecordZoneID {
        return zone.zoneID
    }
}
