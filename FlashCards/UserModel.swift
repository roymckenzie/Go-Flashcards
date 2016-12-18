//
//  UserModel.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/3/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation

public let _user = User()

open class User {
    open var subjects        = [Subject]()
    open var userDefaults:   UserDefaults!

    open class func sharedInstance() -> User {
        return _user
    }
    
    public init() {
        refreshSubjects()
    }
    
    open func refreshSubjects() {
        userDefaults = UserDefaults(suiteName: "group.com.roymckenzie.flashcards")
        if let data = userDefaults.object(forKey: "subjects") as? Data {
            NSKeyedUnarchiver.setClass(Subject.self, forClassName: "Subject")
            subjects = NSKeyedUnarchiver.unarchiveObject(with: data) as! [Subject]
        }
    }
    
    open func addSubject(_ subject: Subject) {
        subjects.append(subject)
        saveSubjects()
    }
    
    open func removeSubject(_ subject: Subject) {
        subjects.enumerated().forEach { index, _subject in
            if _subject == subject {
                subjects.remove(at: index)
            }
        }
        saveSubjects()
    }
    
    open func updateSubject(_ subject: Subject) {
        subjects.enumerated().forEach { index, _subject in
            if _subject == subject {
                _subject.name = subject.name
            }
        }
        User.sharedInstance().saveSubjects()
    }
    
    open func subject(_ id: Int) -> Subject {
        return subjects.filter { (subject) -> Bool in
            return subject.id == id
        }.first!
    }
    
    open func newIndex() -> Int {
        var newIndex = 0
        for subject in subjects {
            if subject.id > newIndex {
                newIndex = subject.id
            }
        }
        return newIndex + 1
    }
    
    open func saveSubjects() {
        let data = NSKeyedArchiver.archivedData(withRootObject: User.sharedInstance().subjects)
        userDefaults.set(data, forKey: "subjects")
        userDefaults.synchronize()
    }
}
