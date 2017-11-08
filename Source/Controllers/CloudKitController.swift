//
//  CloudKitController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/18/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit

enum CloudKitControllerError: Error {
    case iCloudAccountNotAvailable
    case recordHasNoShare
}

private let ICloudAccountAvailable = "ICloudAccountAvailable"

/// CloudKit database access controller
struct CloudKitController {}

extension CloudKitController {
    
    static var iCloudAccountAvailable: Bool {
        get {
            return UserDefaults.standard.bool(forKey: ICloudAccountAvailable)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: ICloudAccountAvailable)
        }
    }
    
    @discardableResult
    public static func checkCloudKitSubscriptions() -> Promise<Void> {
        let promise = Promise<Void>()
        
        checkCurrentSubscriptions(StackZone.private)
            .then {
                return checkCurrentSubscriptions(StackZone.shared)
            }
            .then({ (_) in
                promise.fulfill(())
            })
            .catch { error in
                NSLog("Error checking notifications: \(error.localizedDescription)")
                promise.reject(error)
            }
        
        return promise
    }
    
    @discardableResult
    public static func checkAccountStatus() -> Promise<Bool> {
        return Promise<Bool>(work: { fulfill, reject in
            CKContainer.default().accountStatus() { status, error in
                switch status {
                case .available:
                    fulfill(true)
                case .noAccount, .restricted, .couldNotDetermine:
                    reject(CloudKitControllerError.iCloudAccountNotAvailable)
                }
            }
        })
    }
    
    @discardableResult
    public static func checkCurrentSubscriptions<T: RecordZone>(_ zone: T) -> Promise<Void> {
        return Promise<Void>(work: { fulfill, reject in
            zone.database?
                .fetchAllSubscriptions { subscriptions, error in
                    
                    if let error = error {
                        reject(error)
                    }
                    
                    if let subscriptions = subscriptions {
                        if let _ = subscriptions.first(where: {
                            $0.subscriptionID == zone.subscriptionID
                        }) {
                        } else {
                            subscribeTo(zone)
                        }
                        fulfill(())
                    }
            }
        })
    }
    
    @discardableResult
    public static func clearSubscriptionsFor<T: RecordZone>(_ zone: T) -> Promise<Void> {
        return Promise<Void>(work: { fulfill, reject in
            
            let subscriptionsOperation = CKModifySubscriptionsOperation(subscriptionsToSave: nil,
                                                                        subscriptionIDsToDelete: [zone.subscriptionID])
            subscriptionsOperation.modifySubscriptionsCompletionBlock = { _, _, error in
                if let error = error {
                    reject(error)
                    return
                }
                
                fulfill(())
            }
            
            zone.database?.add(subscriptionsOperation)
        })
    }
    
    public static func subscribeTo<T: RecordZone>(_ zone: T) {
        
        guard let subscription = zone.subscription else {
            return
        }
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription],
                                                       subscriptionIDsToDelete: nil)
        
        operation.modifySubscriptionsCompletionBlock = { subscriptions, _ , error in
            
            if let error = error {
                NSLog("Could not save stacks subscription notification: \(error.localizedDescription)")
            }
            
            if let subscriptionID = subscriptions?.first?.subscriptionID {
                NSLog("Saved subscription notification: \(subscriptionID)")
            }
        }
        
        zone.database?.add(operation)
    }
        
    @discardableResult
    public static func setup<T: RecordZone>(_ zone: T) -> Promise<Void> {
        var zone = zone
        
        let promise = Promise<Void>()
        
        if zone.didSetupZone {
            promise.fulfill(())
            return promise
        }
        
        zone.database?
            .save(T.zone) { _recordZone, error in

                if let error = error {
                    promise.reject(error)
                }
                
                if let _ = _recordZone {
                    zone.didSetupZone = true
                    promise.fulfill(())
                }
            }
        
        return promise
    }
    
    @available(iOS 10.0, *)
    public static func fetchShareFor(_ recordID: CKRecordID) -> Promise<CKShare> {
        return Promise<CKShare>(work: { fulfill, reject in
            let database: CKDatabase
            if recordID.zoneID.ownerName != CKOwnerDefaultName {
                database = CKContainer.default().sharedCloudDatabase
            } else {
                database = CKContainer.default().privateCloudDatabase
            }
            database.fetch(withRecordID: recordID) { record, error in
                    
                if let error = error {
                    reject(error)
                    return
                }
                
                if let record = record {
                    guard let shareRecordID = record.share?.recordID else {
                        reject(CloudKitControllerError.recordHasNoShare)
                        return
                    }
                    database.fetch(withRecordID: shareRecordID) { (shareRecord, error) in
                                
                        if let error = error {
                            reject(error)
                            return
                        }
                        
                        if let shareRecord = shareRecord {
                            fulfill(shareRecord as! CKShare)
                        }
                    }
                }
            }
        })
        
    }
    
    @available(iOS 10.0, *)
    public static func acceptShares(with cloudKitShareMetadatas: [CKShareMetadata]) -> Promise<Void> {
        
        let promise = Promise<Void>()
        
        let operation = CKAcceptSharesOperation(shareMetadatas: cloudKitShareMetadatas)
        
        operation.perShareCompletionBlock = { _, _, error in
            if let error = error {
                promise.reject(error)
                return
            }
        }
        operation.acceptSharesCompletionBlock = { error in
            
            if let error = error {
                promise.reject(error)
                return
            }

            promise.fulfill(())
        }
        
        operation.qualityOfService = .userInteractive
        CKContainer.default().add(operation)
        
        return promise
    }
    
}

