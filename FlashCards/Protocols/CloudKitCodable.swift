//
//  CloudKitCodable.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/18/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit

public protocol CloudKitCodable {
    init?(record: CKRecord) throws
}

struct CloudKitDecoder {
    let record: CKRecord
    
    var recordName: String {
        return record.recordID.recordName
    }
    
    var recordChangeTag: String? {
        return record.recordChangeTag
    }
    
    var modified: Date {
        return record.modificationDate ?? Date()
    }
    
    enum DecodeError: Error {
        case type(key: String, objectType: Any)
        
        var localizedDescription: String {
            switch self {
            case .type(let key, let objectType):
                return "Could not decode key: \(key) for type: \(objectType)"
            }
        }
    }
}

import UIKit

extension CloudKitDecoder {
    
    public func decode<A>(_ key: String) throws -> A {
        guard let value = record.object(forKey: key) as? A else {
            throw DecodeError.type(key: key, objectType: A.self)
        }
        return value
    }
    
    public func decodeAsset(_ key: String) throws -> String {
        guard let value = record.object(forKey: key) as? CKAsset else {
            throw DecodeError.type(key: key, objectType: CKAsset.self)
        }
        guard let string = try value.image?.saveToHomeDirectory(withRecordName: recordName, key: key) else {
            throw DecodeError.type(key: key, objectType: CKAsset.self)
        }
        return string
    }
}
