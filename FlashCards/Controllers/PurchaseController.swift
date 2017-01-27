//
//  PurchaseController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/26/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import Foundation
import SwiftyStoreKit
import StoreKit

enum InAppPurchaseSubscription: String {
    case sixMonths = "PublicLibrarySixMonths"
    case oneYear = "PublicLibraryOneYear"
    
    func verifyActive(receipt: ReceiptInfo) -> Bool {
        let result = SwiftyStoreKit.verifySubscription(productId: rawValue,
                                                       inReceipt: receipt)
        switch result {
        case .purchased(let expiresDate):
            print("Product is valid until \(expiresDate)")
            return true
        case .expired(let expiresDate):
            print("Product is expired since \(expiresDate)")
            return false
        case .notPurchased:
            print("The user has never purchased this product")
            return false
        }
    }
}

enum PurchaseControllerError: Error {
    case purchaseFailed
}

struct PurchaseController {
    static let `default` = PurchaseController()
    
    var currentEnvironmentReceiptURLType: AppleReceiptValidator.VerifyReceiptURLType {
        #if RELEASE
            return .production
        #endif
        return .sandbox
    }
    
    private static var sharedSecret = "2c0a97b172924a889e1a648d558e24dd"
    
    
    func verifyActiveSubscription() -> Promise<Bool> {
        let promise = Promise<Bool>()
        
        let appleValidator = AppleReceiptValidator(service: currentEnvironmentReceiptURLType)
        
        SwiftyStoreKit.verifyReceipt(using: appleValidator,
                                     password: PurchaseController.sharedSecret)
        { result in

            switch result {
            case .success(let receipt):
                
                let activeOneYear = InAppPurchaseSubscription.oneYear.verifyActive(receipt: receipt)
                let activeSixMonths = InAppPurchaseSubscription.sixMonths.verifyActive(receipt: receipt)
                
                if activeOneYear || activeSixMonths {
                    promise.fulfill(true)
                } else {
                    promise.fulfill(false)
                }
            case .error(let error):
                NSLog("Receipt verification failed: \(error.localizedDescription)")
                switch error {
                case .noReceiptData:
                    promise.fulfill(false)
                default:
                    promise.reject(error)
                }
            }
        }
        
        return promise
    }
    
    func getProducts() -> Promise<[SKProduct]> {
        let promise = Promise<[SKProduct]>()
        
        let productIds = Set(arrayLiteral:
            InAppPurchaseSubscription.sixMonths.rawValue,
            InAppPurchaseSubscription.oneYear.rawValue
        )
        
        SwiftyStoreKit.retrieveProductsInfo(productIds) { results in
            
            var products = [SKProduct]()
            
            if let error = results.error {
                NSLog("Error retrieving products: \(error.localizedDescription)")
                promise.reject(error)
                return
            }
            
            for product in results.retrievedProducts {
                NSLog("Retrieved Product: \(product.localizedTitle) for \(product.localizedPrice)")
                products.append(product)
            }
            
            for productId in results.invalidProductIDs {
                NSLog("Invalid Product: \(productId)")
            }
            
            promise.fulfill(products)
        }
        
        return promise
    }
    
    func purchase(_ subscription: InAppPurchaseSubscription) -> Promise<Bool> {
        let promise = Promise<Bool>()
        
        SwiftyStoreKit.purchaseProduct(subscription.rawValue, atomically: true) { result in
            switch result {
            case .success(let product):
                print("Purchase Success: \(product.productId)")
                promise.fulfill(true)
            case .error(let error):
                print("Purchase Failed: \(error)")
                let error = PurchaseControllerError.purchaseFailed
                promise.reject(error)
            }
        }
        
        return promise
    }
}
