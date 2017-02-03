//
//  QuizletStack.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/22/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import Foundation

struct QuizletStack {
    let id: Int
    let name: String
    let description: String
    let cardCount: Int
    let created: TimeInterval
    let modified: TimeInterval
    let hasImages: Bool
    let frontLanguageCode: String
    let backLanguageCode: String
    var cards = [QuizletCard]()
}

extension QuizletStack {
    
    var createdDate: Date {
        return Date(timeIntervalSince1970: created)
    }

    var modifiedDate: Date {
        return Date(timeIntervalSince1970: modified)
    }
    
    var frontLanguage: String? {
        return Locale.autoupdatingCurrent.localizedString(forLanguageCode: frontLanguageCode)
    }
    
    var backLanguage: String? {
        return Locale.autoupdatingCurrent.localizedString(forLanguageCode: backLanguageCode)
    }
}

extension QuizletStack {
    
    
    // Initialize from JSON data
    init(jsonObject: JSONObject) {
        self.id = jsonObject["id"] as! Int
        self.name = jsonObject["title"] as! String
        self.description = jsonObject["description"] as! String
        self.cardCount = jsonObject["term_count"] as! Int
        self.created = jsonObject["created_date"] as! TimeInterval
        self.modified = jsonObject["modified_date"] as! TimeInterval
        self.hasImages = jsonObject["has_images"] as! Bool
        self.frontLanguageCode = jsonObject["lang_terms"] as! String
        self.backLanguageCode = jsonObject["lang_definitions"] as! String
        
        if let cardsJson = jsonObject["terms"] as? [JSONObject] {
            let cards = cardsJson.flatMap(QuizletCard.init)
            self.cards.append(contentsOf: cards)
        }
    }
}

struct QuizletCard {
    let id: Int
    let frontText: String
    let backText: String
    let imageUrlPath: String?
    
    // temp storage for saving a stack locally
    var localImagePath: String?
}

extension QuizletCard {
    
    var backImageUrl: URL? {
        guard let imageUrlPath = imageUrlPath else { return nil }
        return URL(string: imageUrlPath)
    }
    
    var largeBackImageUrl: URL? {
        guard let imageUrlPath = imageUrlPath else { return nil }
        let largeUrlPath = imageUrlPath.replacingOccurrences(of: "_m.jpg", with: ".jpg")
        return URL(string: largeUrlPath)
    }
}

extension QuizletCard {

    // Initialize from JSON data
    init(jsonObject: JSONObject) {
        self.id = jsonObject["id"] as! Int
        self.frontText = jsonObject["term"] as! String
        self.backText = jsonObject["definition"] as! String
        if let imageJson = jsonObject["image"] as? JSONObject {
            self.imageUrlPath = imageJson["url"] as? String
        } else {
            self.imageUrlPath = nil
        }
    }
}
