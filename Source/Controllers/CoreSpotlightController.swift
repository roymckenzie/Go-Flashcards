//
//  CoreSpotlightController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 2/3/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit
import CoreSpotlight
import RealmSwift

final class CoreSpotlightController {
    
    static func reindex() {

        CSSearchableIndex.default().deleteAllSearchableItems { error in
            if let error = error {
                print("\(error.localizedDescription)")
            }
            self.addItems()
        }
    }
    
    private static func addItems() {
        let realm = try! Realm()
        
        let stacks = realm.objects(Stack.self)
        
        var searchableItems = [CSSearchableItem]()
        
        stacks.forEach { stack in
            let attributes = CSSearchableItemAttributeSet(itemContentType: "Stack")
            attributes.title = stack.name
            attributes.contentDescription = stack.progressDescription
            let item = CSSearchableItem(uniqueIdentifier: stack.id, domainIdentifier: "com.roymckenzie.FlashCards", attributeSet: attributes)
            searchableItems.append(item)
        }
        
        let cards = realm.objects(Card.self)
        
        cards.forEach { card in
            let attributes = CSSearchableItemAttributeSet(itemContentType: "Card")
            attributes.title = card.frontText
            attributes.thumbnailURL = card.frontImageUrl ?? card.backImageUrl
            attributes.contentDescription = card.backText
            let item = CSSearchableItem(uniqueIdentifier: card.id, domainIdentifier: card.stack?.id, attributeSet: attributes)
            searchableItems.append(item)
        }
        
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error = error {
                print("\(error.localizedDescription)")
            }
        }
        
    }
}

extension AppDelegate {
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        
        switch  userActivity.activityType {
        case CSSearchableItemActionType:
            guard let itemIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
                return true
            }
            showViewFor(itemIdentifier: itemIdentifier,
                        application: application)
            return true
        default:
            return true
        }
    }
    
    func showViewFor(itemIdentifier: String, application: UIApplication) {
        let realm = try! Realm()
        
        if let stack = realm.object(ofType: Stack.self, forPrimaryKey: itemIdentifier) {
            showViewFor(stack)
        } else if let card = realm.object(ofType: Card.self, forPrimaryKey: itemIdentifier) {
            showViewFor(card)
        }
        
    }
    
    private func showViewFor(_ card: Card) {
        let vc = Storyboard.main.instantiateViewController(FlashCardViewController.self)
        vc.card = card
        UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: false, completion: nil)
    }

    private func showViewFor(_ stack: Stack) {
        let mainNC = Storyboard.main.instantiateViewController(with: Storyboard.Identifier.myStacksNavigationController)
        let vc = Storyboard.main.instantiateViewController(FlashCardsViewController.self)
        vc.stack = stack
        
        UIApplication.shared.keyWindow?.rootViewController = mainNC
        (mainNC as? UINavigationController)?.pushViewController(vc, animated: false)
    }
}
