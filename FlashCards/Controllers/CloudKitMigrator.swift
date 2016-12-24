//
//  CloudKitMigrator.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/23/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit

private let CloudKitMigratedKey = "CloudKitMigratedKey"
struct CloudKitMigrator {
    
    /// User's private database
    private var cloudDatabase: CKDatabase {
        return CloudKitController.current.privateDB
    }
    
    /// User's standard user defaults
    private static var standardDefaults: UserDefaults {
        return UserDefaults.standard
    }
    
    /// Old subjects from data manager
    private var oldSubjects: [Subject] {
        return DataManager.current.subjects
    }
    
    /// Returns `true` if user has migrated to iCloud
    private static var didMigrateToCloudKit: Bool {
        get {
            return standardDefaults.bool(forKey: CloudKitMigratedKey)
        }
        set {
            standardDefaults.set(newValue, forKey: CloudKitMigratedKey)
        }
    }
    
    /// Migrates the user data if they have data to migrate
    /// and if they haven't already migrated
    func migrateIfNeeded() -> Promise<Bool> {
        let promise = Promise<Bool>()
        if oldSubjects.isEmpty {
            CloudKitMigrator.didMigrateToCloudKit = true
            promise.fulfill(false)
            return promise
        }
        if CloudKitMigrator.didMigrateToCloudKit {
            promise.fulfill(false)
            return promise
        }
        
        // Show activity indicator
        let loadingView = LoadingView(labelText: "Cleaning up")
        loadingView.show()
        
        let subjectPromises = self.oldSubjects.flatMap { self.migrateSubject(subject: $0) }
        
        Promise<Any>
            .all(subjectPromises)
            .then { _ in
                CloudKitMigrator.didMigrateToCloudKit = true
                DataManager.current.userDefaults.removeObject(forKey: "subjects")
                promise.fulfill(true)
            }
            .always {
                loadingView.hide()
            }
            .catch { error in
                promise.reject(error)
                print("Error migrating subjects: \(error)")
        }
        
        return promise
    }
    
    private func migrateSubject(subject: Subject) -> Promise<Void> {
        return Promise<(CKRecord, [Card])>(work: { fulfill, reject in
            let record = CKRecord(recordType: .stack)
            record.setObject(subject.name as NSString, forKey: RecordType.Stack.name.rawValue)
            
            self.cloudDatabase.save(record) { subjectRecord, error in
                if let error = error {
                    print("Could not save Stack \"\(subject.name)\" to iCloud: \(error)")
                    reject(error)
                    return
                } else if let subjectRecord = subjectRecord {
                    fulfill((subjectRecord, subject.cards))
                }
            }
        }).then(self.migrateCards)
    }
    
    private func migrateCards(subjectRecord: CKRecord, cards: [Card]) -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            let reference = CKReference(record: subjectRecord, action: CKReferenceAction.deleteSelf)
            
            // Create records to add to iCloud
            let records = cards.map { card -> CKRecord in
                let record = CKRecord(recordType: .card)
                record.setObject(card.topic as NSString, forKey: RecordType.Card.topic.rawValue)
                record.setObject(card.details as NSString, forKey: RecordType.Card.details.rawValue)
                record.setObject(reference, forKey: RecordType.Card.stack.rawValue)
                return record
            }
            
            // Batch records into one operation
            let recordOperation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            recordOperation.modifyRecordsCompletionBlock = { records, recordIds, error in
                if let error = error {
                    print("Could not save Card to iCloud: \(error)")
                    reject(error)
                    return
                } else if let _ = records {
                    fulfill()
                }
            }
            
            // Add operation to database
            self.cloudDatabase.add(recordOperation)
        }
    }
}
