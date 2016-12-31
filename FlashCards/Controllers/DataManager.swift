//
//  DataManager.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/18/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation

struct DataManager {
    public var oldSubjects = [OldSubject]()
    
    public static var current = DataManager()
}
