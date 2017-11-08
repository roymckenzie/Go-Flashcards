//
//  CloudKitSyncManager.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/23/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit
import RealmSwift
import UIKit

enum CloutKitSyncManagerError: Error {
    case unknown
    case unknownRecordType
}

private let FirstSyncCompletedKey = "FirstSyncCompletedKey"
private let PreviousSharedServerChangeTokenKey = "PreviousSharedServerChangeTokenKey"
private let PreviousPrivateServerChangeTokenKey = "PreviousPrivateServerChangeTokenKey"

final class CloudKitSyncManager {
    
    private let realm = try! Realm()
    
    private var syncing = false
    
    func pauseSyncing() {
        syncing = true
    }
    
    func resumeSyncing() {
        syncing = false
    }
    
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
        realmNotificationToken?.invalidate()
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
        realmNotificationToken = realm.observe() { [weak self] notification, realm in
            
            switch notification {
            case .didChange:
                if self?.syncing == true { return }
                self?.runPushSync()
                
            case .refreshRequired:
                self?.realm.refresh()
                break
            }
        }
    }
    
    @discardableResult
    open func runSync() -> Promise<Void> {
        
        let promise = Promise<Void>()
        
        syncing = true
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
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
                return self.firstPull(StackZone.private, recordType: .stackPreferences)
            }
            .then {
                return self.firstSyncCompleted = true
            }
            .then {
                return self.pull(StackZone.private)
            }
            .always {
                self.syncing = false
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                promise.fulfill(())
            }
            .catch { error in
                promise.reject(error)
                print("Error running FULL SYNC: \(error.localizedDescription)")
        }
        
        return promise
    }
    
    @discardableResult
    open func runPushSync() -> Promise<Void> {
        
        let promise = Promise<Void>()
        
        syncing = true
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        pushPrivate()
            .then { () -> Promise<Void> in 
                if #available(iOS 10.0, *) {
                    return self.pushShared()
                } else {
                    return Promise<Void>(value: ())
                }
            }
            .always {
                self.syncing = false
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                promise.fulfill(())
            }
            .catch { error in
                promise.reject(error)
                print("Error running PUSH ONLY sync: \(error.localizedDescription)")
        }
        
        return promise
    }
    
    @discardableResult
    private func pushPrivate(batchDivisor: Int = 1) -> Promise<Void> {
        
        print("Running CloudKit Push Private Sync")
        let promise = Promise<Void>()
        
        let realm = try! Realm()
        
        let stackRecordsToSave = Array(realm.objects(Stack.self)).filter({ $0.needsPrivateSave }).flatMap({ $0.record })
        let stackIdsToDelete = Array(realm.objects(Stack.self)).filter({ $0.needsPrivateDelete }).flatMap({ $0.recordID })
        let cardRecordsToSave = Array(realm.objects(Card.self)).filter({ $0.needsPrivateSave }).flatMap({ $0.record })
        let cardIdsToDelete = Array(realm.objects(Card.self)).filter({ $0.needsPrivateDelete }).flatMap({ $0.recordID })
        let stackPrefRecordsToSave = Array(realm.objects(StackPreferences.self)).filter({ $0.needsPrivateSave }).flatMap({ $0.record })
        let stackPrefIdsToDelete = Array(realm.objects(StackPreferences.self)).filter({ $0.needsPrivateDelete }).flatMap({ $0.recordID })
        
        var recordsToSave = stackRecordsToSave + cardRecordsToSave + stackPrefRecordsToSave
        var recordsToDelete = stackIdsToDelete + cardIdsToDelete + stackPrefIdsToDelete
        
        if recordsToSave.isEmpty && recordsToDelete.isEmpty {
            promise.fulfill(())
            return promise
        }
        
        if batchDivisor > 1 {
            let amountofSaveToRemove = recordsToSave.count / batchDivisor
            recordsToSave.removeLast(amountofSaveToRemove)
            
            let amountOfDeleteToRemove = recordsToDelete.count / batchDivisor
            recordsToDelete.removeLast(amountOfDeleteToRemove)
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordsToDelete)
        operation.savePolicy = .changedKeys
        operation.modifyRecordsCompletionBlock = { [weak self] recordsSaved, recordIdsDeleted, error in
            guard let _self = self else { return }
            if let error = error {
                guard let error = error as? CKError else { return }
                switch error.code {
                case .limitExceeded:
                    _self.pushPrivate(batchDivisor: batchDivisor+1)
                        .then {
                            return _self.pushPrivate()
                        }
                        .then({ (_) in
                            promise.fulfill(())
                        })
                        .catch { error in
                            promise.reject(error)
                            print("Failed BATCH PRIVATE PUSH: \(error.localizedDescription)")
                        }
                case .partialFailure:
                    var recordIdsToDelete = [CKRecordID]()
                    error.partialErrorsByItemID?.forEach { key, value in
                        guard let recordId = key as? CKRecordID else { return }
                        recordIdsToDelete.append(recordId)
                    }
                    if let recordIdsDeleted = recordIdsDeleted {
                        recordIdsToDelete.append(contentsOf: recordIdsDeleted)
                    }
                    self?.updateRealmRecords(recordsSaved: recordsSaved, recordIdsDeleted: recordIdsToDelete)
                    promise.reject(error)
                default: break
                }
                return
            }
            
            self?.updateRealmRecords(recordsSaved: recordsSaved, recordIdsDeleted: recordIdsDeleted)
            promise.fulfill(())
        }
        
        CKContainer.default().privateCloudDatabase.add(operation)
        
        return promise
    }

    @available(iOS 10.0, *)
    @discardableResult
    private func pushShared() -> Promise<Void> {
        
        print("Running CloudKit Push Shared Sync")
        
        let promise = Promise<Void>()

        let realm = try! Realm()
        
        let stackRecordsToSave = Array(realm.objects(Stack.self)).filter({ $0.needsSharedSave }).flatMap({ $0.record })
        let stackIdsToDelete = Array(realm.objects(Stack.self)).filter({ $0.needsSharedDelete }).flatMap({ $0.recordID})
        let cardRecordsToSave = Array(realm.objects(Card.self)).filter({ $0.needsSharedSave }).flatMap({ $0.record })
        let cardIdsToDelete = Array(realm.objects(Card.self)).filter({ $0.needsSharedDelete }).flatMap({ $0.recordID })
        
        let recordsToSave = stackRecordsToSave + cardRecordsToSave
        let recordsToDelete = stackIdsToDelete + cardIdsToDelete
        
        if recordsToSave.isEmpty && recordsToDelete.isEmpty {
            promise.fulfill(())
            return promise
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordsToDelete)
        operation.savePolicy = .changedKeys
        operation.modifyRecordsCompletionBlock = { [weak self] recordsSaved, recordIdsDeleted, error in
            
            if let error = error {
                guard let error = error as? CKError else { return }
                var recordIdsToDelete = [CKRecordID]()
                error.partialErrorsByItemID?.forEach { key, value in
                    guard let recordId = key as? CKRecordID else { return }
                    recordIdsToDelete.append(recordId)
                }
                if let recordIdsDeleted = recordIdsDeleted {
                    recordIdsToDelete.append(contentsOf: recordIdsDeleted)
                }
                self?.updateRealmRecords(recordsSaved: recordsSaved, recordIdsDeleted: recordIdsToDelete)
                promise.reject(error)
                return
            }
            
            self?.updateRealmRecords(recordsSaved: recordsSaved, recordIdsDeleted: recordIdsDeleted)
            promise.fulfill(())
        }
        
        CKContainer.default().sharedCloudDatabase.add(operation)
        
        return promise
    }

    @available(iOS 10.0, *)
    @discardableResult
    private func pullShared<T: RecordZone>(_ zone: T) -> Promise<Void> {
        
        print("Running CloudKit Pull Shared Sync")

        let promise = Promise<Void>()
        
        var zone = zone

        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: zone.previousSharedDatabaseServerChangeToken)
        
        var recordZoneIDsToProcess = [CKRecordZoneID]()
        var recordZoneIDsToDelete = [CKRecordZoneID]()
        
        operation.fetchDatabaseChangesCompletionBlock = { newServerChangeToken, moreComing, error in
            
            if let error = error {
                promise.reject(error)
                return
            }
            
            if let newServerChangeToken = newServerChangeToken {
                zone.previousSharedDatabaseServerChangeToken = newServerChangeToken

                self.deleteDataWith(recordZoneIDsToDelete)
                if recordZoneIDsToProcess.isEmpty {
                    promise.fulfill(())
                    return
                }
                self.fetchChanges(in: recordZoneIDsToProcess, in: zone)
                    .then {
                        promise.fulfill(())
                    }
                    .catch { error in
                        promise.reject(error)
                    }
            }

        }
        
        operation.recordZoneWithIDWasDeletedBlock = { recordZoneID in
            recordZoneIDsToDelete.append(recordZoneID)
        }
        
        operation.recordZoneWithIDChangedBlock = { recordZoneID in
            recordZoneIDsToProcess.append(recordZoneID)
        }
        
        zone.database?.add(operation)
        
        return promise
    }
    
    func deleteDataWith(_ recordZoneIDs: [CKRecordZoneID]) {
    
        if recordZoneIDs.isEmpty { return }
        
        print("Delete data associated with deleted record zone")
        
        let realm = try! Realm()
        
        let owners = recordZoneIDs.flatMap { $0.ownerName }
        
        let ownerNamesPredicate = NSPredicate(format: "recordOwnerName IN %@", owners)

        let stacksToDelete   = realm.objects(Stack.self).filter(ownerNamesPredicate)
        let cardsToDelete    = Array(Set(realm.objects(Card.self).filter(ownerNamesPredicate) + stacksToDelete.flatMap { $0.cards }))
        let stackPrefsToDelete = stacksToDelete.flatMap { $0.preferences }
        
        let date = Date()
        try? realm.write {
            stacksToDelete.setValue(date, forKey: "deleted")
            stacksToDelete.setValue(date, forKey: "modified")
            
            cardsToDelete.forEach { $0.deleted = date; $0.modified = date }
            stackPrefsToDelete.forEach { $0.deleted = date; $0.modified = date }
        }
    }
    
    @available(iOS 10.0, *)
    func fetchChanges(in recordZoneIDs: [CKRecordZoneID], in zone: RecordZone) -> Promise<Void> {

        let promise = Promise<Void>()
        
        var zone = zone

        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: recordZoneIDs,
                                                          optionsByRecordZoneID: nil)
            
        var recordsToSave = [CKRecord]()
        var recordIDsToDelete = [CKRecordID]()
        
        operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, _, moreComing, error in
            
            if let error = error {
                promise.reject(error)
                return
            }
            
            if let _ = changeToken {
//                zone.previousSharedDatabaseServerChangeToken = changeToken
            }
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { _, changeToken, _ in
            zone.previousSharedDatabaseServerChangeToken = changeToken
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            
            if let error = error {
                promise.reject(error)
                return
            }
            
            self.save(recordsToSave)
            self.delete(recordIDsToDelete)
            promise.fulfill(())
        }
        
        operation.recordWithIDWasDeletedBlock = { recordID, _ in
            recordIDsToDelete.append(recordID)
        }
        
        operation.recordChangedBlock = { record in
            recordsToSave.append(record)
        }
        

        zone.database?.add(operation)

        return promise
    }
    
    @available(iOS 10.0, *)
    @discardableResult
    private func pullZoneChanges<T: RecordZone>(_ zone: T) -> Promise<Void> {
        
        print("Running CloudKit Pull Private (iOS 10) Sync")
        
        var zone = zone
        let promise = Promise<Void>()
        
        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = zone.previousZoneServerChangeToken
        let recordZoneOptions = [
            T.zoneID: options
        ]
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [T.zoneID], optionsByRecordZoneID: recordZoneOptions)
        
        var recordsToSave = [CKRecord]()
        var recordIDsToDelete = [CKRecordID]()
        
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            
            if let error = error {
                promise.reject(error)
                return
            }
            
            self.save(recordsToSave)
            self.delete(recordIDsToDelete)
            
            promise.fulfill(())
        }
        
        operation.recordChangedBlock = { record in
            recordsToSave.append(record)
        }
        
        operation.recordWithIDWasDeletedBlock = { recordID, _ in
            recordIDsToDelete.append(recordID)
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { _, changeToken, _ in
            if let changeToken = changeToken {
                zone.previousZoneServerChangeToken = changeToken
            }
        }
        
        operation.recordZoneFetchCompletionBlock = { _, changeToken, _, moreComing, error in
            if let error = error {
                promise.reject(error)
            }
            
            if let changeToken = changeToken {
                zone.previousZoneServerChangeToken = changeToken
            }
            
            if moreComing {
                self.pullZoneChanges(zone)
                return
            }
        }
        
        zone.database?.add(operation)
        
        return promise
    }
    
    @discardableResult
    private func pull<T: RecordZone>(_ zone: T) -> Promise<Void> {
        var zone = zone
        
        if #available(iOS 10.0, *) {
            if zone.database?.databaseScope == .shared {
                return pullShared(zone)
            } else if zone.database?.databaseScope == .private {
                return pullZoneChanges(zone)
            }
        }
        
        print("Running CloudKit Pull Private Sync")

        let promise = Promise<Void>()
    
        let operation = CKFetchRecordChangesOperation(recordZoneID: T.zoneID,
                                                      previousServerChangeToken: zone.previousZoneServerChangeToken)
        
        var recordsToSave = [CKRecord]()
        var recordIDsToDelete = [CKRecordID]()
        
        operation.fetchRecordChangesCompletionBlock = { newServerChangeToken, _, error in
            
            if let error = error {
                promise.reject(error)
                return
            }
            
            zone.previousZoneServerChangeToken = newServerChangeToken
            self.save(recordsToSave)
            self.delete(recordIDsToDelete)
            promise.fulfill(())
        }
        
        operation.recordWithIDWasDeletedBlock = { recordID in
            recordIDsToDelete.append(recordID)
        }
        
        operation.recordChangedBlock = { record in
            recordsToSave.append(record)
        }
        
        zone.database?.add(operation)
    
        return promise
    }
    
    private func deleteRecordWith(id recordID: CKRecordID) {
        let realm = try! Realm()
        
        let matchingStack = realm.object(ofType: Stack.self, forPrimaryKey: recordID.recordName)
        let matchingCard = realm.object(ofType: Card.self, forPrimaryKey: recordID.recordName)
        let matchingStackPrefs = realm.object(ofType: StackPreferences.self, forPrimaryKey: recordID.recordName)
        
        try? realm.write {
            if let matchingStack = matchingStack {
                realm.delete(matchingStack)
            }
            
            if let matchingCard = matchingCard {
                realm.delete(matchingCard)
            }
            
            if let matchingStackPrefs = matchingStackPrefs {
                realm.delete(matchingStackPrefs)
            }
        }
    }
    
    func save(_ records: [CKRecord], makeCopy: Bool = false) {
        let realm = try! Realm()
        
        let stackRecordTypes = records.filter({ $0.recordType == RecordType.stack.description })
        let cardRecordTypes = records.filter({ $0.recordType == RecordType.card.description })
        let stackPrefsRecordTypes = records.filter({ $0.recordType == RecordType.stackPreferences.description })
        
        let stackRecords = (try? stackRecordTypes.flatMap(Stack.init)) ?? []
        let cardRecords = (try? cardRecordTypes.flatMap(Card.init)) ?? []
        let stackPrefs = (try? stackPrefsRecordTypes.flatMap(StackPreferences.init)) ?? []
        
        if makeCopy {
            var stackIdTable = [String: String]()
            stackRecordTypes.forEach({ stackIdTable[$0.recordID.recordName] = UUID().uuidString })
            
            stackRecords.forEach {
                $0.id = stackIdTable[$0.id]!
                $0.recordOwnerName = CKOwnerDefaultName
                $0.preferences = StackPreferences(stack: $0)
            }
            
            cardRecords.forEach {
                $0.id = UUID().uuidString
                $0.recordOwnerName = CKOwnerDefaultName
                $0.stackReferenceName = stackIdTable[$0.stackReferenceName!]
                $0.frontImageUpdated = true
                $0.backImageUpdated = true
            }
        }
        
        try? realm.write {
            
            stackRecords.forEach { stack in
                if let existingStack = realm.object(ofType: Stack.self,
                                                    forPrimaryKey: stack.id) {
                    stack.cards.append(objectsIn: existingStack.cards)
                    stack.preferences = existingStack.preferences
                }
                
                realm.create(Stack.self, value: stack, update: true)
            }
            
            
            
            cardRecords.forEach { card in
                guard let stackReferenceName = card.stackReferenceName else {
                    print("Processed a CloudKit Card object with no Stack object reference.")
                    return
                }
                
                // Find Stack object to append Card object to
                guard let stack = realm.object(ofType: Stack.self, forPrimaryKey: stackReferenceName) else {
                    print("Processed a CloudKit Stack object, but could not find Stack object to append to.")
                    return
                }
                
                if let existingCard = realm.object(ofType: Card.self, forPrimaryKey: card.id) {
                    card.order = existingCard.order
                    card.mastered = existingCard.mastered
                }
                
                realm.add(card, update: true)
                // If Stack object doesn't contain this card append it
                if !stack.cards.contains(card) {
                    stack.cards.append(card)
                }
            }
        }
        
        try? realm.write {
        
            stackPrefs.forEach { stackPref in
                guard let stackReferenceName = stackPref.stackReferenceName else {
                    print("Processed a CloudKit Stack Preference object with no Stack object reference.")
                    return
                }
                
                // Find Stack object to add preferences object to
                guard let stack = realm.object(ofType: Stack.self, forPrimaryKey: stackReferenceName) else {
                    print("Processed a CloudKit Stack Preferences object, but could not find Stack object to append to.")
                    return
                }
                
                realm.add(stackPref, update: true)
                // If Stack object doesn't contain these preferences add it
                if stack.preferences == nil {
                    stack.preferences = stackPref
                }
                
                for cardOrder in stackPref.ordered {
                    let card = stack.cards.first(where: { $0.id == cardOrder.key })
                    card?.order = cardOrder.value
                }
                
                for cardMastered in stackPref.mastered {
                    let card = stack.cards.first(where: { $0.id == cardMastered.key })
                    if let timeInterval = cardMastered.value {
                        card?.mastered = Date(timeIntervalSince1970: timeInterval)
                    } else {
                        card?.mastered = nil
                    }
                }

            }
        }
        
        updateRealmRecords(recordsSaved: records, recordIdsDeleted: nil)
    }
    
    private func delete(_ recordIDs: [CKRecordID]) {
        updateRealmRecords(recordsSaved: nil, recordIdsDeleted: recordIDs)
    }
    
    @discardableResult
    private func firstPull<T: RecordZone>(_ zone: T, recordType: RecordType, withCursor cursor: CKQueryCursor? = nil) -> Promise<Void> {
        
        let promise = Promise<Void>()

        if firstSyncCompleted {
            promise.fulfill(())
            return promise
        }
        
        print("Running CloudKit First Time \(recordType.description) Pull Sync")
        
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
                promise.reject(error)
                return
            }

            self?.save(recordsToSave)
            
            if let cursor = cursor {
                self?.firstPull(zone, recordType: recordType, withCursor:  cursor)
                    .then({ _ in
                        promise.fulfill(())
                    })
                    .catch { error in
                        promise.reject(error)
                    }
                return
            }
            
            promise.fulfill(())
        }
        
        operation.recordFetchedBlock = { record in
            recordsToSave.append(record)
        }
        
        zone.database?.add(operation)
        
        return promise
    }
    
    private func updateRealmRecords(recordsSaved: [CKRecord]?, recordIdsDeleted: [CKRecordID]?) {
        let syncedIds = recordsSaved?.flatMap({ $0.recordID.recordName })
        let deleteIds = recordIdsDeleted?.flatMap({ $0.recordName })
        
        let syncedIdsPredicate = NSPredicate(format: "id IN %@", syncedIds ?? [])
        let deleteIdsPredicate = NSPredicate(format: "id IN %@", deleteIds ?? [])
        
        let realm = try! Realm()
        
        let syncedStacks        = realm.objects(Stack.self).filter(syncedIdsPredicate)
        let syncedCards         = realm.objects(Card.self).filter(syncedIdsPredicate)
        let syncedStackPrefs     = realm.objects(StackPreferences.self).filter(syncedIdsPredicate)
        
        let deleteStacks        = realm.objects(Stack.self).filter(deleteIdsPredicate)
        let deleteCards         = realm.objects(Card.self).filter(deleteIdsPredicate)
        let deleteStackPrefs     = realm.objects(StackPreferences.self).filter(deleteIdsPredicate)
        
        let dateSynced = Date()
        
        do {
            try realm.write {
                syncedStacks.setValue(dateSynced, forKey: "synced")
                syncedCards.setValue(dateSynced, forKey: "synced")
                syncedStackPrefs.setValue(dateSynced, forKey: "synced")
                realm.delete(deleteStackPrefs)
                realm.delete(deleteCards)
                realm.delete(deleteStacks)
            }
        } catch {
            print("Error processing new CloudKit records: \(error)")
        }
    }
}
