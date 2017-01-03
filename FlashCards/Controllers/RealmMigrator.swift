//
//  RealmMigrator.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/26/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation
import RealmSwift

private let DidMigrateKey = "DidMigrateKey"

/// Handles migrating data from old UserDefaults store to Realm
struct RealmMigrator {
    
    private static var didMigrate: Bool {
        get {
            return UserDefaults.standard.bool(forKey: DidMigrateKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DidMigrateKey)
        }
    }
    
    static func runMigration() {
        if didMigrate { return }
        
        let oldSubjects = getOldSubjects()
        
        let newStacks = oldSubjects.flatMap(newStackFrom)
        
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(newStacks)
            }
            didMigrate = true
        } catch {
            NSLog("Could not add items to Realm in RealmMigrator: \(error)")
        }
    }
    
    private static func getOldSubjects() -> [OldSubject] {
        guard let data = UserDefaults(suiteName: "group.com.roymckenzie.flashcards")?
            .object(forKey: "subjects") as? Data else {
                return []
        }
        NSKeyedUnarchiver.setClass(OldSubject.classForKeyedUnarchiver(), forClassName: "FlashCardsKit.Subject")
        guard let subjects = NSKeyedUnarchiver.unarchiveObject(with: data) as? [OldSubject] else {
            return []
        }
        return subjects
    }
    
    private static func newStackFrom(oldSubject: OldSubject) -> Stack {
        let stack = Stack()
        let newCards = oldSubject.cards.flatMap(newCardFrom)
        stack.name = oldSubject.name
        stack.cards.append(objectsIn: newCards)
        return stack
    }
    
    private static func newCardFrom(oldCard: OldCard) -> Card {
        let card = Card()
        card.frontText  = oldCard.topic
        card.backText = oldCard.detail
        card.mastered = oldCard.hidden ? Date() : nil
        card.order = Double(oldCard.order)
        return card
    }
}
