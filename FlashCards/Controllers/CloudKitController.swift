//
//  CloudKitController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/18/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit

enum RecordType: String {
    case card
    case stack
    
    enum Card: String {
        case topic
        case details
        case stack
    }
    
    enum Stack: String {
        case name
    }
}

extension RecordType: CustomStringConvertible {
    
    var description: String {
        return self.rawValue.capitalized
    }
}

/// CloudKit database access controller
struct CloudKitController {
    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase
    
    static let current: CloudKitController = CloudKitController()
    
    init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
}

extension CloudKitController {
    
    public func getStacks() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: .stack, predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) { records, error in
            guard let stack = records?.first else { return }
            self.getCardsFromStack(record: stack)
        }
    }
    
    public func getCardsFromStack(record: CKRecord) {
        let reference = CKReference(record: record, action: .none)
        let predicate = NSPredicate(format: "stack == %@", reference)
        let query = CKQuery(recordType: .card, predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) { records, error in
            print("******* CARDS ********")
            guard let card = records?.first else { return }
            
            guard let newCard = try? NewCard(record: card) else { return }
            print(newCard)
        }
    }
}

private let CloudKitMigratedKey = "CloudKitMigratedKey"
struct CloudKitMigrator {
    
    /// User's private database
    private var cloudDatabase: CKDatabase {
        return CloudKitController.current.privateDB
    }

    /// User's standard user defaults
    private var standardDefaults: UserDefaults {
        return UserDefaults.standard
    }
    
    /// Old subjects from data manager
    private var oldSubjects: [Subject] {
        return DataManager.current.oldSubjects
    }

    /// Returns `true` if user has migrated to iCloud
    private var didMigrateToCloudKit: Bool {
        get {
            return standardDefaults.bool(forKey: CloudKitMigratedKey)
        }
        set {
            standardDefaults.set(newValue, forKey: CloudKitMigratedKey)
        }
    }
    
    /// Migrates the user data if they have data to migrate
    /// and if they haven't already migrated
    func checkIfMigrationNeeded() {
        if oldSubjects.isEmpty { return }
        if didMigrateToCloudKit { return }
        
        // Show activity indicator
        let loadingView = LoadingView(labelText: "Cleaning up")
        loadingView.show()
        
        Promise<Void>(value: ())
            .then { () -> [Promise<Void>] in
                let promises: [Promise<Void>] = self.oldSubjects.flatMap { self.migrateSubject(subject: $0) }
                return promises
            }
            .then { promises -> Promise<[Void]>  in
                let promises: Promise<[Void]> = Promise<Any>.all(promises)
                return promises
            }
            .always {
                loadingView.hide()
            }
            .catch { error in
                print("Error migrating subjects: \(error)")
            }
    }
    
    private func migrateSubject(subject: Subject) -> Promise<Void> {
        return Promise<(CKRecord, [Card])>(work: { fulfill, reject in
            let recordName = "\(subject.id)-\(subject.name)-\(Date().timeIntervalSince1970)"
            let recordId = CKRecordID(recordName: recordName)
            let record = CKRecord(recordType: .stack, recordID: recordId)
            
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
                let recordName = "\(card.id)-\(card.topic)-\(Date().timeIntervalSince1970)"
                let recordId = CKRecordID(recordName: recordName)
                let record = CKRecord(recordType: .card, recordID: recordId)
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
            
            // Add oepration to database
            self.cloudDatabase.add(recordOperation)
        }
    }
}

// MARK:- CKQuery extension
extension CKQuery {
    
    /// Initialize a `CKQuery` with a `RecordType` enum value
    convenience init(recordType: RecordType, predicate: NSPredicate) {
        self.init(recordType: recordType.description, predicate: predicate)
    }
}

// MARK:- CKRecord extension
extension CKRecord {
    
    /// Initialize a `CKRecord` with a `RecordType` enum value
    convenience init(recordType: RecordType, recordID: CKRecordID) {
        self.init(recordType: recordType.rawValue, recordID: recordID)
    }
}
