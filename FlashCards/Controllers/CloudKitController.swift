//
//  CloudKitController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/18/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit

struct CloudKitController {
    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase
    
    static let current: CloudKitController = CloudKitController()
    
    enum RecordType: String {
        case card
        case stack
    }
    
    init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
}

extension CloudKitController.RecordType: CustomStringConvertible {
    
    var description: String {
        return self.rawValue.capitalized
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

struct DataMigrator {
    private var cloudDatabase: CKDatabase {
        return CloudKitController.current.privateDB
    }

    var standardDefaults: UserDefaults {
        return UserDefaults.standard
    }

    var didMigrateToCloudKit: Bool {
        get {
            return standardDefaults.bool(forKey: "cloudKitMigrated")
        }
        set {
            standardDefaults.set(newValue, forKey: "cloudKitMigrated")
        }
    }
    
    func migrateData() {
        print("Did migrate to CloudKit \(didMigrateToCloudKit)")
        let subjects = DataManager.current.oldSubjects
        if subjects.isEmpty { return }
        if didMigrateToCloudKit { return }

        subjects.forEach { subject in
            let recordName = "\(subject.id)-\(subject.name)-\(Date().timeIntervalSince1970)"
            let recordId = CKRecordID(recordName: recordName)
            let record = CKRecord(recordType: .stack, recordID: recordId)
            record.setObject(subject.name as NSString, forKey: "name")
            cloudDatabase.save(record) { subjectRecord, error in
                if let error = error {
                    print("Could not save Stack \"\(subject.name)\" to iCloud: \(error)")
                }
                guard let subjectRecord = subjectRecord else { return }
                self.migrateCards(subjectRecord: subjectRecord, cards: subject.cards)
            }
        }
    }
    
    func migrateCards(subjectRecord: CKRecord, cards: [Card]) {
        cards.forEach { card in
            let recordName = "\(card.id)-\(card.topic)-\(Date().timeIntervalSince1970)"
            let recordId = CKRecordID(recordName: recordName)
            let record = CKRecord(recordType: .card, recordID: recordId)
            let reference = CKReference(record: subjectRecord, action: CKReferenceAction.deleteSelf)
            record.setObject(card.topic as NSString, forKey: "topic")
            record.setObject(card.details as NSString, forKey: "details")
            record.setObject(reference, forKey: "stack")
            cloudDatabase.save(record) { cardRecord, error in
                if let error = error {
                    print("Could not save Card \"\(card.topic)\" to iCloud: \(error)")
                }
            }
        }
    }
}

extension CKQuery {
    
    /// Create query with FlashCards types
    convenience init(recordType: CloudKitController.RecordType, predicate: NSPredicate) {
        self.init(recordType: recordType.description, predicate: predicate)
    }
}

extension CKRecord {
    
    convenience init(recordType: CloudKitController.RecordType, recordID: CKRecordID) {
        self.init(recordType: recordType.rawValue, recordID: recordID)
    }
}

struct DataManager {
    let userDefaults: UserDefaults
    public var subjects        = [Subject]()
    public var oldSubjects        = [Subject]()
    
    public static var current = DataManager()
    
    public init() {
        userDefaults = UserDefaults(suiteName: "group.com.roymckenzie.flashcards")!
        refreshSubjects()
    }
    
    public mutating func refreshSubjects() {
        if let data = userDefaults.object(forKey: "subjects") as? Data {
            NSKeyedUnarchiver.setClass(Subject.self, forClassName: "Subject")
            guard let subjects = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Subject] else { return }
            self.subjects = subjects
            self.oldSubjects = subjects
        }
    }
    
    public mutating func addSubject(_ subject: Subject) {
        subjects.append(subject)
        saveSubjects()
    }
    
    public mutating func removeSubject(_ subject: Subject) {
        subjects.enumerated().forEach { index, _subject in
            if _subject == subject {
                subjects.remove(at: index)
            }
        }
        saveSubjects()
    }
    
    public func updateSubject(_ subject: Subject) {
        subjects.enumerated().forEach { index, _subject in
            if _subject == subject {
                _subject.name = subject.name
            }
        }
        DataManager.current.saveSubjects()
    }
    
    public func subject(_ id: Int) -> Subject {
        return subjects.filter { (subject) -> Bool in
            return subject.id == id
            }.first!
    }
    
    public func newIndex() -> Int {
        var newIndex = 0
        for subject in subjects {
            if subject.id > newIndex {
                newIndex = subject.id
            }
        }
        return newIndex + 1
    }
    
    public func saveSubjects() {
        let data = NSKeyedArchiver.archivedData(withRootObject: DataManager.current.subjects)
        userDefaults.set(data, forKey: "subjects")
        userDefaults.synchronize()
    }

}
