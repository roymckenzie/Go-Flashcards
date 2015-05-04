//
//  UserModel.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/3/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation

let _user = User()

class User {
    var subjects        = [Subject]()
    var userDefaults:   NSUserDefaults!

    class func sharedInstance() -> User {
        return _user
    }
    
    init() {
        userDefaults = NSUserDefaults(suiteName: "group.com.roymckenzie.flashcards")
        if let data = userDefaults.objectForKey("subjects") as? NSData {
            NSKeyedUnarchiver.setClass(Subject.self, forClassName: "Subject")
            subjects = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [Subject]
        }
        
        // MARK: 0.2 migration: Migrate from old model in 0.1
        if let data = userDefaults.objectForKey("cards") as? NSData {
            NSKeyedUnarchiver.setClass(Card.self, forClassName: "Card")
            let cards = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [Card]
            let oldSubject = Subject(name: "Untitled", id: newIndex())
                oldSubject.cards = cards
            subjects.append(oldSubject)
            userDefaults.setObject(nil, forKey: "cards")
        }
    }
    
    func addSubject(subject: Subject) {
        subjects.append(subject)
        saveSubjects()
    }
    
    func removeSubject(subject: Subject) {
        for (index, _subject) in enumerate(subjects) {
            if _subject == subject {
                subjects.removeAtIndex(index)
            }
        }
        saveSubjects()
    }
    
    func subject(id: Int) -> Subject {
        return subjects.filter { (subject) -> Bool in
            return subject.id == id
        }.first!
    }
    
    func newIndex() -> Int {
        var newIndex = 0
        for subject in subjects {
            if subject.id > newIndex {
                newIndex = subject.id
            }
        }
        return newIndex + 1
    }
    
    func saveSubjects() {
        NSKeyedArchiver.setClassName("Subject", forClass: Subject.self)
        let data = NSKeyedArchiver.archivedDataWithRootObject(User.sharedInstance().subjects)
        userDefaults.setObject(data, forKey: "subjects")
        userDefaults.synchronize()
    }
}
