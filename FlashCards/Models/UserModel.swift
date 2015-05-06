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
