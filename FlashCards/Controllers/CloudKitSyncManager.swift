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
private let PreviousServerChangeTokenKey = "PreviousServerChangeTokenKey"
final class CloudKitSyncManager {
    
    private let realm = try! Realm()
    
    private var syncing = false
    
    static let current = CloudKitSyncManager()
    
    var realmNotificationToken: NotificationToken?
    
    private var cloudDatabase: CKDatabase {
        return CloudKitController.current.privateDB
    }
    
    var previousServerChangeToken: CKServerChangeToken? {
        get {
            guard let data = UserDefaults.standard.data(forKey: PreviousServerChangeTokenKey) else {
                return nil
            }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.set(nil, forKey: PreviousServerChangeTokenKey)
                return
            }
            let data = NSKeyedArchiver.archivedData(withRootObject: newValue)
            UserDefaults.standard.set(data, forKey: PreviousServerChangeTokenKey)
        }
    }

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
    
    func startRealmNotification() {
        do {
            let realm = try Realm()
            realmNotificationToken = realm.addNotificationBlock() { [weak self] notification, realm in
                switch notification {
                case .didChange:
                    if self?.syncing == false {
                        self?.syncing = true
                        self?.push().always { self?.syncing = false }
                    }
                case .refreshRequired:
                    self?.realm.refresh()
                    break
                }
            }
        } catch {
            NSLog("Error setting up Realm Notification: \(error)")
        }
    }
    
    func setupNotifications() {
        
        // For Realm Changes
        
        startRealmNotification()
        
        // For CloudKit Changes
        NotificationCenter.default.addObserver(forName: .stackZoneUpdated,
                                               object: nil,
                                               queue: nil) { [weak self] notification in
            if self?.syncing == false {
                self?.syncing = true
                self?.pull().always { self?.syncing = false }
            }
        }
    }
    
    open func runSync() {
        
        syncing = true
        
        push()
            .then {
                return self.firstPull(recordType: .stack)
            }
            .then {
                return self.firstPull(recordType: .card)
            }
            .then {
                return self.firstSyncCompleted = true
            }
            .then {
                return self.pull()
            }
            .always {
                self.syncing = false
            }
            .catch { error in
                NSLog("Error running sync: \(error)")
            }

    }
    
    @discardableResult
    private func push() -> Promise<Void> {

        NSLog("Running CloudKit Push Sync")

        return Promise<Void>(work: { [weak self] fulfill, reject in
            let realm = try! Realm()
            
            let stackRecordsToSave = Array(realm.objects(Stack.self)).filter({ $0.needsSave }).flatMap({ $0.record })
            let stackIdsToDelete = Array(realm.objects(Stack.self)).filter({ $0.needsDelete }).flatMap({ $0.recordID})
            let cardRecordsToSave = Array(realm.objects(Card.self)).filter({ $0.needsSave }).flatMap({ $0.record })
            let cardIdsToDelete = Array(realm.objects(Card.self)).filter({ $0.needsDelete }).flatMap({ $0.recordID })
            
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
                    NSLog("Error Running CloudKit Push Sync: \(error.localizedDescription)")
                    return
                }
                
                self?.updateRealmRecords(recordsSaved: recordsSaved, recordIdsDeleted: recordIdsDeleted)
                fulfill()
            }
            
            CKContainer.default().privateCloudDatabase.add(operation)
        })
    }
    
    @discardableResult
    private func pull() -> Promise<Void> {
        
        NSLog("Running CloudKit Pull Sync")
        
        return Promise<Void>(work: { [weak self] fulfill, reject in
            let operation = CKFetchRecordChangesOperation(recordZoneID: RecordZone.stackZone.zoneID,
                                                          previousServerChangeToken: self?.previousServerChangeToken)
            
            operation.fetchRecordChangesCompletionBlock = { [weak self] newServerChangeToken, _, error in
                
                if let error = error {
                    reject(error)
                    NSLog("Error fetching record changes from CloudKit: \(error)")
                    return
                }
                
                self?.previousServerChangeToken = newServerChangeToken
                fulfill()
            }
            
            operation.recordWithIDWasDeletedBlock = { recordId in
                let realm = try! Realm()
                
                let matchingStack = realm.object(ofType: Stack.self, forPrimaryKey: recordId.recordName)
                let matchingCard = realm.object(ofType: Card.self, forPrimaryKey: recordId.recordName)
                
                try? realm.write {
                    if let matchingStack = matchingStack {
                        realm.delete(matchingStack)
                    }
                    
                    if let matchingCard = matchingCard {
                        realm.delete(matchingCard)
                    }
                }
            }
            
            operation.recordChangedBlock = { record in
                
                let realm = try? Realm()
                
                switch record.recordType {
                case RecordType.stack.description:
                    guard let stack = try? Stack(record: record).unsafelyUnwrapped else { return }
                    
                    try? realm?.write {
                        // Check if the record currently has Card objects
                        // if it does add them to the new Stack object
                        if let existingStack = realm?.object(ofType: Stack.self,
                                                             forPrimaryKey: stack.recordID.recordName) {
                            stack.cards.append(objectsIn: existingStack.cards)
                        }
                        realm?.add(stack, update: true)
                    }
                    
                case RecordType.card.description:
                    guard let card = try? Card(record: record).unsafelyUnwrapped else { return }
                    
                    guard let stackReferenceName = card.stackReferenceName else {
                        NSLog("Processed a CloudKit Card object with no Stack object reference.")
                        return
                    }

                    // Find Stack object to append Card object to
                    guard let stack = realm?.object(ofType: Stack.self, forPrimaryKey: stackReferenceName) else {
                        NSLog("Processed a CloudKit Card object, but could not find Stack object to append to.")
                        return
                    }
                    
                    try? realm?.write {
                        realm?.add(card, update: true)
                        
                        // If Stack object doesn't contain this card append it
                        if !stack.cards.contains(card) {
                            stack.cards.append(card)
                        }
                    }

                    
                default:
                    break
                }
            }
            
            CKContainer.default().privateCloudDatabase.add(operation)
        })
    }
    
    @discardableResult
    private func firstPull(recordType: RecordType, withCursor cursor: CKQueryCursor? = nil) -> Promise<Void> {
        
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
            operation.zoneID = RecordZone.stackZone.zoneID
            
            var cards =  [Card]()
            var stacks = [Stack]()
            
            operation.queryCompletionBlock = { [weak self] cursor, error in
                if let error = error {
                    reject(error)
                    return
                }

                let realm = try! Realm()
                
                try? realm.write {
                    realm.add(stacks, update: true)
                    
                    cards.forEach { card in
                        guard let stack = realm.object(ofType: Stack.self, forPrimaryKey: card.stackReferenceName) else { return }
                        realm.add(card, update: true)
                        stack.cards.append(card)
                    }
                }
                
                if let cursor = cursor {
                    self?.firstPull(recordType: recordType, withCursor:  cursor)
                    return
                }
                
                fulfill()
            }
            
            operation.recordFetchedBlock = { record in
                
                switch record.recordType {
                case RecordType.stack.description:
                    guard let _stack = try? Stack(record: record), let stack = _stack else { return }
                    stacks.append(stack)
                case RecordType.card.description:
                    guard let _card = try? Card(record: record), let card = _card else { return }
                    cards.append(card)
                default: break
                }
            }
            
            CKContainer.default().privateCloudDatabase.add(operation)
        })
    }
    
    private func updateRealmRecords(recordsSaved: [CKRecord]?, recordIdsDeleted: [CKRecordID]?) {
        let syncedIds = recordsSaved?.flatMap({ $0.recordID.recordName })
        let deleteIds = recordIdsDeleted?.flatMap({ $0.recordName })
        
        let syncedIdsPredicate = NSPredicate(format: "id IN %@", syncedIds ?? [])
        let deleteIdsPredicate = NSPredicate(format: "id IN %@", deleteIds ?? [])
        
        let realm = try! Realm()
        
        let syncedStacks    = realm.objects(Stack.self).filter(syncedIdsPredicate)
        let syncedCards     = realm.objects(Card.self).filter(syncedIdsPredicate)
        
        let deleteStacks    = realm.objects(Stack.self).filter(deleteIdsPredicate)
        let deleteCards     = realm.objects(Card.self).filter(deleteIdsPredicate)
        
        let dateSynced = Date()
        
        do {
            try realm.write {
                syncedStacks.setValue(dateSynced, forKey: "synced")
                syncedCards.setValue(dateSynced, forKey: "synced")
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
