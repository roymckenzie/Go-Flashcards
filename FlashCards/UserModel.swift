//
//  UserModel.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/3/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import Foundation

public let _user = User()

public class User {
    public var subjects        = [Subject]()
    public var userDefaults:   NSUserDefaults!

    public class func sharedInstance() -> User {
        return _user
    }
    
    public init() {
        refreshSubjects()
    }
    
    public func refreshSubjects() {
        userDefaults = NSUserDefaults(suiteName: "group.com.roymckenzie.flashcards")
        if let data = userDefaults.objectForKey("subjects") as? NSData {
            NSKeyedUnarchiver.setClass(Subject.self, forClassName: "Subject")
            subjects = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [Subject]
        }
    }
    
    public func addSubject(subject: Subject) {
        subjects.append(subject)
        saveSubjects()
    }
    
    public func removeSubject(subject: Subject) {
        for (index, _subject) in enumerate(subjects) {
            if _subject == subject {
                subjects.removeAtIndex(index)
            }
        }
        saveSubjects()
    }
    
    public func updateSubject(subject: Subject) {
        for (index, _subject) in enumerate(subjects) {
            if _subject == subject {
                _subject.name = subject.name
            }
        }
        User.sharedInstance().saveSubjects()
    }
    
    public func subject(id: Int) -> Subject {
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
        let data = NSKeyedArchiver.archivedDataWithRootObject(User.sharedInstance().subjects)
        userDefaults.setObject(data, forKey: "subjects")
        userDefaults.synchronize()
    }
}
