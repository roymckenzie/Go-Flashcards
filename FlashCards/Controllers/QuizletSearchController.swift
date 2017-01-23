//
//  QuizletSearchController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/22/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import Foundation

typealias JSONObject = [String: Any]

struct QuizletSearchController {
    
    private static let clientId = "5kPh42xKCG"
    private static let version = "2.0"
    private static let baseUrlPath = "https://api.quizlet.com/"
    
    private static var apiUrlPath: String {
        return baseUrlPath + version
    }
    
    private static var searchSetsUrlPath: String {
        return apiUrlPath + "/search/sets"
    }
    
    private static var setsUrlPath: String {
        return apiUrlPath + "/sets"
    }
    
    static func search(query: String) -> Promise<[QuizletStack]> {
        let promise = Promise<[QuizletStack]>()

        // Build params
        let params = [
            "q": query,
            "client_id": clientId
        ]

        // Build URL
        var components = URLComponents(string: searchSetsUrlPath)!
        components.queryItems = params.flatMap { URLQueryItem.init(name: $0.key, value: $0.value) }
        
        // Build request
        let request = URLRequest(url: components.url!)
        
        // Perform Request
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            if let error = error {
                promise.reject(error)
                return
            }
            
            if let data = data {
                let json: JSONObject
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! JSONObject
                } catch {
                    promise.reject(error)
                    return
                }
                guard let stacksJson = json["sets"] as? [JSONObject] else { return }
                let stacks = stacksJson.flatMap(QuizletStack.init)
                promise.fulfill(stacks)
            }
            
        }.resume()
        
        return promise
    }
    
    static func get(stackId: Int) -> Promise<QuizletStack> {
        let promise = Promise<QuizletStack>()
        
        // Build params
        let params = [
            "client_id": clientId
        ]
        
        // Build URL
        var components = URLComponents(string: setsUrlPath + "/\(stackId)")!
        components.queryItems = params.flatMap { URLQueryItem.init(name: $0.key, value: $0.value) }
        
        // Build request
        let request = URLRequest(url: components.url!)
        
        // Perform Request
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            if let error = error {
                promise.reject(error)
                return
            }
            
            if let data = data {
                let json: JSONObject
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! JSONObject
                } catch {
                    promise.reject(error)
                    return
                }
                let stack = QuizletStack(jsonObject: json)
                promise.fulfill(stack)
            }
            
            }.resume()
        
        return promise
    }
}
