//
//  DataManager.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/18/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation

struct DataManager {
    let userDefaults: UserDefaults
    public var subjects     = [Subject]()
    
    public static var current = DataManager()
    
    public init() {
        userDefaults = UserDefaults(suiteName: "group.com.roymckenzie.flashcards")!
        refreshSubjects()
    }
    
    public mutating func refreshSubjects() {
        if let data = userDefaults.object(forKey: "subjects") as? Data {
            NSKeyedUnarchiver.setClass(Subject.self, forClassName: "Subject")
            guard let subjects = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Subject] else { return }
            self.subjects = subjects
        }
    }
    
    public mutating func addSubject(_ subject: Subject) {
        subjects.append(subject)
        saveSubjects()
    }
    
    public mutating func removeSubject(_ subject: Subject) {
        subjects.enumerated().forEach { index, _subject in
            if _subject == subject {
                subjects.remove(at: index)
            }
        }
        saveSubjects()
    }
    
    public func updateSubject(_ subject: Subject) {
        subjects.enumerated().forEach { index, _subject in
            if _subject == subject {
                _subject.name = subject.name
            }
        }
        DataManager.current.saveSubjects()
    }
    
    public func subject(_ id: Int) -> Subject {
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
        let data = NSKeyedArchiver.archivedData(withRootObject: DataManager.current.subjects)
        userDefaults.set(data, forKey: "subjects")
        userDefaults.synchronize()
    }
}
