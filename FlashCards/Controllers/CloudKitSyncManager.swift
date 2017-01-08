//
//  CloudKitSyncManager.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/23/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit
import RealmSwift

enum CloutKitSyncManagerError: Error {
    case unknown
    case unknownRecordType
}

private let FirstSyncCompletedKey = "FirstSyncCompletedKey"
private let PreviousPrivateServerChangeTokenKey = "PreviousPrivateServerChangeTokenKey"
private let PreviousSharedServerChangeTokenKey = "PreviousSharedServerChangeTokenKey"

final class CloudKitSyncManager {
    
    private let realm = try! Realm()
    
    private var syncing = false
    
    static let current = CloudKitSyncManager()
    
    var realmNotificationToken: NotificationToken?

    var firstSyncCompleted: Bool {
        get {
            return UserDefaults.standard.bool(forKey: FirstSyncCompletedKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: FirstSyncCompletedKey)
        }
    }
    
    deinit {
        NSLog("CloudSyncManager deinit")
        realmNotificationToken?.stop()
    }
    
    func setupNotifications() {
        
        // For Realm Changes
        startRealmNotification()
        
        // For Shared CloudKit Changes
        NotificationCenter.default.addObserver(forName: StackZone.shared.notificationName,
                                               object: nil,
                                               queue: nil) { [weak self] notification in
            if self?.syncing == true { return }
            self?.syncing = true
            self?.pull(StackZone.shared)
                .always {
                    self?.syncing = false
                }
        }
        
        // For Private CloudKit Changes
        NotificationCenter.default.addObserver(forName: StackZone.private.notificationName,
                                               object: nil,
                                               queue: nil) { [weak self] notification in
            if self?.syncing == true { return }
            self?.syncing = true
            self?.pull(StackZone.private).always {
                self?.syncing = false
            }
        }
    }
    
    func startRealmNotification() {
        realmNotificationToken = realm.addNotificationBlock() { [weak self] notification, realm in
            
            switch notification {
            case .didChange:
                if self?.syncing == true { return }
                self?.runSync()
                
            case .refreshRequired:
                self?.realm.refresh()
                break
            }
        }
    }
    
    open func runSync() {
        
        syncing = true
        
        pushPrivate()
            .then {
                if #available(iOS 10.0, *) {
                    return self.pushShared()
                } else {
                    return Promise<Void>(value: ())
                }
            }
            .then {
                return self.pull(StackZone.shared)
            }
            .then {
                return self.firstPull(StackZone.private, recordType: .stack)
            }
            .then {
                return self.firstPull(StackZone.private, recordType: .card)
            }
            .then {
                return self.firstPull(StackZone.private, recordType: .userCardPreferences)
            }
            .then {
                return self.firstSyncCompleted = true
            }
            .then {
                return self.pull(StackZone.private)
            }
            .then {
                return self.pull(StackZone.shared)
            }
            .always {
                self.syncing = false
            }
            .catch { error in
                NSLog("Error running sync: \(error)")
            }

    }
    
    @discardableResult
    private func pushPrivate() -> Promise<Void> {
        
        NSLog("Running CloudKit Push Private Sync")
        
        return Promise<Void>(work: { [weak self] fulfill, reject in
            let realm = try! Realm()
            
            let stackRecordsToSave = Array(realm.objects(Stack.self)).filter({ $0.needsPrivateSave }).flatMap({ $0.record })
            let stackIdsToDelete = Array(realm.objects(Stack.self)).filter({ $0.needsPrivateDelete }).flatMap({ $0.recordID })
            let cardRecordsToSave = Array(realm.objects(Card.self)).filter({ $0.needsPrivateSave }).flatMap({ $0.record })
            let cardIdsToDelete = Array(realm.objects(Card.self)).filter({ $0.needsPrivateDelete }).flatMap({ $0.recordID })
            let cardPrefRecordsToSave = Array(realm.objects(UserCardPreferences.self)).filter({ $0.needsPrivateSave }).flatMap({ $0.record })
            let cardPrefIdsToDelete = Array(realm.objects(UserCardPreferences.self)).filter({ $0.needsPrivateDelete }).flatMap({ $0.recordID })
            
            let recordsToSave = stackRecordsToSave + cardRecordsToSave + cardPrefRecordsToSave
            let recordsToDelete = stackIdsToDelete + cardIdsToDelete + cardPrefIdsToDelete
            
            if recordsToSave.isEmpty && recordsToDelete.isEmpty {
                fulfill()
                return
            }
            
            let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordsToDelete)
            operation.savePolicy = .changedKeys
            operation.modifyRecordsCompletionBlock = { [weak self] recordsSaved, recordIdsDeleted, error in
                
                if let error = error {
                    reject(error)
                    NSLog("Error Running CloudKit Push Sync: \(error.localizedDescription)")
                    return
                }
                
                self?.updateRealmRecords(recordsSaved: recordsSaved, recordIdsDeleted: recordIdsDeleted)
                fulfill()
            }
            
            CKContainer.default().privateCloudDatabase.add(operation)
        })
    }

    @available(iOS 10.0, *)
    @discardableResult
    private func pushShared() -> Promise<Void> {
        
        NSLog("Running CloudKit Push Shared Sync")
        
        return Promise<Void>(work: { [weak self] fulfill, reject in
            let realm = try! Realm()
            
            let stackRecordsToSave = Array(realm.objects(Stack.self)).filter({ $0.needsSharedSave }).flatMap({ $0.record })
            let stackIdsToDelete = Array(realm.objects(Stack.self)).filter({ $0.needsSharedDelete }).flatMap({ $0.recordID})
            let cardRecordsToSave = Array(realm.objects(Card.self)).filter({ $0.needsSharedSave }).flatMap({ $0.record })
            let cardIdsToDelete = Array(realm.objects(Card.self)).filter({ $0.needsSharedDelete }).flatMap({ $0.recordID })
            
            let recordsToSave = stackRecordsToSave + cardRecordsToSave
            let recordsToDelete = stackIdsToDelete + cardIdsToDelete
            
            if recordsToSave.isEmpty && recordsToDelete.isEmpty {
                fulfill()
                return
            }
            
            let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordsToDelete)
            operation.savePolicy = .changedKeys
            operation.modifyRecordsCompletionBlock = { [weak self] recordsSaved, recordIdsDeleted, error in
                
                if let error = error {
                    reject(error)
                    NSLog("Error Running CloudKit Shared Push Sync: \(error.localizedDescription)")
                    return
                }
                
                self?.updateRealmRecords(recordsSaved: recordsSaved, recordIdsDeleted: recordIdsDeleted)
                fulfill()
            }
            
            CKContainer.default().sharedCloudDatabase.add(operation)
        })
    }

    @available(iOS 10.0, *)
    @discardableResult
    private func pullShared<T: RecordZone>(_ zone: T) -> Promise<Void> {
        
        NSLog("Running CloudKit Pull Shared Sync")

        let promise = Promise<Void>()
        var zone = zone

        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: zone.previousSharedDatabaseServerChangeToken)
        
        var recordZoneIDsToProcess = [CKRecordZoneID]()
        
        operation.fetchDatabaseChangesCompletionBlock = { newServerChangeToken, moreComing, error in
            
            if let error = error {
                NSLog("Error running CloudKit Pull Shared: \(error)")
                promise.reject(error)
                return
            }
            
            if let newServerChangeToken = newServerChangeToken {
                zone.previousSharedDatabaseServerChangeToken = newServerChangeToken

                self.fetchChanges(in: recordZoneIDsToProcess, in: zone.database)
                    .then {
                        promise.fulfill()
                    }
                    .catch { error in
                        NSLog("Could not fetch shared changes: \(error)")
                        promise.reject(error)
                    }
            }

        }
        
        operation.recordZoneWithIDChangedBlock = { recordZoneID in
            recordZoneIDsToProcess.append(recordZoneID)
        }
        
        zone.database?.add(operation)
        return promise
    }
    
    @available(iOS 10.0, *)
    func fetchChanges(in recordZoneIDs: [CKRecordZoneID], in database: CKDatabase?) -> Promise<Void> {
        return Promise<Void>(work: { fulfill, reject in
            let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: recordZoneIDs,
                                                              optionsByRecordZoneID: nil)
            
            var recordsToSave = [CKRecord]()
            
            operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, _, moreComing, error in
                
                if let error = error {
                    NSLog("Error fetching changes in zone \(zoneID.zoneName): \(error)")
                    reject(error)
                }
                
                if let _ = changeToken {

                    if moreComing {
                        // TODO:- figure out how to pass change token to right method
                        return
                    }
                }
            }
            
            operation.fetchRecordZoneChangesCompletionBlock = { error in
                
                if let error = error {
                    NSLog("Fetch record zone changes failed: \(error)")
                    reject(error)
                    return
                }
                
                self.save(recordsToSave)
                fulfill()
            }
            
            operation.recordWithIDWasDeletedBlock = { recordID, _ in
                self.deleteRecordWith(id: recordID)
            }
            
            operation.recordChangedBlock = { record in
                recordsToSave.append(record)
            }
            
            database?.add(operation)
        })

    }
    
    @discardableResult
    private func pull<T: RecordZone>(_ zone: T) -> Promise<Void> {
        var zone = zone
        
        if #available(iOS 10.0, *) {
            if zone.database?.databaseScope == .shared {
                return pullShared(zone)
            }
        }
        
        NSLog("Running CloudKit Pull Private Sync")

        return Promise<Void>(work: { fulfill, reject in
            let operation = CKFetchRecordChangesOperation(recordZoneID: T.zoneID,
                                                          previousServerChangeToken: zone.previousZoneServerChangeToken)
            
            var recordsToSave = [CKRecord]()
            operation.fetchRecordChangesCompletionBlock = { newServerChangeToken, _, error in
                
                if let error = error {
                    reject(error)
                    NSLog("Error fetching record changes from CloudKit: \(error)")
                    return
                }
                
                zone.previousZoneServerChangeToken = newServerChangeToken
                self.save(recordsToSave)
                fulfill()
            }
            
            operation.recordWithIDWasDeletedBlock = { recordId in
                self.deleteRecordWith(id: recordId)
            }
            
            operation.recordChangedBlock = { record in
                recordsToSave.append(record)
            }
            
            zone.database?.add(operation)
        })
    }
    
    private func deleteRecordWith(id recordID: CKRecordID) {
        let realm = try! Realm()
        
        let matchingStack = realm.object(ofType: Stack.self, forPrimaryKey: recordID.recordName)
        let matchingCard = realm.object(ofType: Card.self, forPrimaryKey: recordID.recordName)
        let matchingCardPrefs = realm.object(ofType: UserCardPreferences.self, forPrimaryKey: recordID.recordName)
        
        try? realm.write {
            if let matchingStack = matchingStack {
                realm.delete(matchingStack)
            }
            
            if let matchingCard = matchingCard {
                realm.delete(matchingCard)
            }
            
            if let matchingCardPrefs = matchingCardPrefs {
                realm.delete(matchingCardPrefs)
            }
        }
    }
    
    private func save(_ records: [CKRecord]) {
        let realm = try! Realm()
        
        let stackRecordTypes = records.filter({ $0.recordType == RecordType.stack.description })
        let cardRecordTypes = records.filter({ $0.recordType == RecordType.card.description })
        let cardPrefsRecordTypes = records.filter({ $0.recordType == RecordType.userCardPreferences.description })
        
        let stackRecords = (try? stackRecordTypes.flatMap(Stack.init)) ?? []
        let cardRecords = (try? cardRecordTypes.flatMap(Card.init)) ?? []
        let cardPrefs = (try? cardPrefsRecordTypes.flatMap(UserCardPreferences.init)) ?? []
        
        try? realm.write {
            
            stackRecords.forEach { stack in
                if let existingStack = realm.object(ofType: Stack.self,
                                                    forPrimaryKey: stack.recordID.recordName) {
                    stack.cards.append(objectsIn: existingStack.cards)
                }
            }

            realm.add(stackRecords, update: true)

            cardRecords.forEach { card in
                guard let stackReferenceName = card.stackReferenceName else {
                    NSLog("Processed a CloudKit Card object with no Stack object reference.")
                    return
                }
                
                // Find Stack object to append Card object to
                guard let stack = realm.object(ofType: Stack.self, forPrimaryKey: stackReferenceName) else {
                    NSLog("Processed a CloudKit Card object, but could not find Stack object to append to.")
                    return
                }
                
                realm.add(card, update: true)
                // If Stack object doesn't contain this card append it
                if !stack.cards.contains(card) {
                    stack.cards.append(card)
                }
            }
            
            cardPrefs.forEach { cardPref in
                guard let cardReferenceName = cardPref.cardReferenceName else {
                    NSLog("Processed a CloudKit User Preference object with no Stack object reference.")
                    return
                }
                
                // Find Stack object to append Card object to
                guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardReferenceName) else {
                    NSLog("Processed a CloudKit User Preferences object, but could not find Card object to append to.")
                    return
                }
                
                realm.add(cardPref, update: true)
                // If Stack object doesn't contain this card append it
                if card.userCardPreferences == nil {
                    card.userCardPreferences = cardPref
                }
            }
        }
        
        updateRealmRecords(recordsSaved: records, recordIdsDeleted: nil)
    }
    
    @discardableResult
    private func firstPull<T: RecordZone>(_ zone: T, recordType: RecordType, withCursor cursor: CKQueryCursor? = nil) -> Promise<Void> {
        
        if firstSyncCompleted {
            return Promise<Void>(value: ())
        }
        
        NSLog("Running CloudKit First Time \(recordType.description) Pull Sync")

        return Promise<Void>(work: { fulfill, reject in
            
            let operation: CKQueryOperation
            if let cursor = cursor {
                operation = CKQueryOperation(cursor: cursor)
            } else {
                let query = CKQuery(recordType: recordType, predicate: NSPredicate.truePredicate)
                operation = CKQueryOperation(query: query)
            }
            operation.zoneID = T.zoneID
            
            var recordsToSave = [CKRecord]()
            
            operation.queryCompletionBlock = { [weak self] cursor, error in
                if let error = error {
                    reject(error)
                    return
                }

                self?.save(recordsToSave)
                
                if let cursor = cursor {
                    self?.firstPull(zone, recordType: recordType, withCursor:  cursor)
                        .then {
                            fulfill()
                        }
                        .catch { error in
                            reject(error)
                        }
                    return
                }
                
                fulfill()
            }
            
            operation.recordFetchedBlock = { record in
                recordsToSave.append(record)
            }
            
            zone.database?.add(operation)
        })
    }
    
    private func updateRealmRecords(recordsSaved: [CKRecord]?, recordIdsDeleted: [CKRecordID]?) {
        let syncedIds = recordsSaved?.flatMap({ $0.recordID.recordName })
        let deleteIds = recordIdsDeleted?.flatMap({ $0.recordName })
        
        let syncedIdsPredicate = NSPredicate(format: "id IN %@", syncedIds ?? [])
        let deleteIdsPredicate = NSPredicate(format: "id IN %@", deleteIds ?? [])
        
        let realm = try! Realm()
        
        let syncedStacks        = realm.objects(Stack.self).filter(syncedIdsPredicate)
        let syncedCards         = realm.objects(Card.self).filter(syncedIdsPredicate)
        let syncedCardPrefs     = realm.objects(UserCardPreferences.self).filter(syncedIdsPredicate)
        
        let deleteStacks        = realm.objects(Stack.self).filter(deleteIdsPredicate)
        let deleteCards         = realm.objects(Card.self).filter(deleteIdsPredicate)
        let deleteCardPrefs     = realm.objects(UserCardPreferences.self).filter(deleteIdsPredicate)
        
        let dateSynced = Date()
        
        do {
            try realm.write {
                syncedStacks.setValue(dateSynced, forKey: "synced")
                syncedCards.setValue(dateSynced, forKey: "synced")
                syncedCardPrefs.setValue(dateSynced, forKey: "synced")
                realm.delete(deleteCardPrefs)
            }
            try realm.write {
                realm.delete(deleteCards)
            }
            try realm.write {
                realm.delete(deleteStacks)
            }
        } catch {
            NSLog("Error processing new CloudKit records: \(error)")
        }
    }
}
