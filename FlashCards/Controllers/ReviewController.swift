//
//  ReviewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/18/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

private let RateTitle = NSLocalizedString("Nice work!", comment: "Review alert title")
private let RateDescription = NSLocalizedString("If you find Go FlashCards useful, would you mind taking a quick moment to rate it?", comment: "Review alert description")
private let RateAppAction = NSLocalizedString("Rate Go FlashCards", comment: "Rate action Text")
private let LaterAction = NSLocalizedString("Remind me later", comment: "Remind later action text")
private let NoThanksAction = NSLocalizedString("No, thanks", comment: "No thanks action text")

private let ReviewRequestLastShownKey = "ReviewRequestLastShownKey"
private let ReviewRequestNeverShowKey = "ReviewRequestNeverShowKey"
private let ReviewRequestDidReviewKey = "ReviewRequestDidReviewKey"

final class ReviewController {
    
    private static var ud: UserDefaults {
        return .standard
    }
    
    private static var neverShow: Bool {
        get {
            return ud.bool(forKey: ReviewRequestNeverShowKey)
        }
        set {
            ud.set(newValue, forKey: ReviewRequestNeverShowKey)
        }
    }
    
    private static var didReview: Bool {
        get {
            return ud.bool(forKey: ReviewRequestDidReviewKey)
        }
        set {
            ud.set(newValue, forKey: ReviewRequestDidReviewKey)
        }
    }

    private static var lastShown: TimeInterval? {
        get {
            let timeInterval = ud.double(forKey: ReviewRequestLastShownKey)
            if timeInterval == 0 { return nil }
            return timeInterval
        }
        set {
            ud.set(newValue, forKey: ReviewRequestLastShownKey)
        }
    }

    private static var shouldShow: Bool {
        if didReview { return false }
        if neverShow { return false }
        guard let lastShown = lastShown else {
            return true
        }
        let currentTimeInterval = Date().timeIntervalSince1970
        return (currentTimeInterval - lastShown) > (86400 * 3) // remind every three days
    }
    
    static func showReviewAlert() {
        if !shouldShow { return }
        
        let alert = UIAlertController(title: RateTitle, message: RateDescription, preferredStyle: .alert)
        
        let rateAction = UIAlertAction(title: RateAppAction, style: .default) { _ in
            self.reviewAppAction()
        }
        alert.addAction(rateAction)
        
        let laterAction = UIAlertAction(title: LaterAction, style: .default, handler: nil)
        alert.addAction(laterAction)
        
        let noAction = UIAlertAction(title: NoThanksAction, style: .default) { _ in
            self.noReviewAction()
        }
        alert.addAction(noAction)
        
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true) {
            self.lastShown = Date().timeIntervalSince1970
        }
    }
    
    private static func reviewAppAction() {
        guard let url = URL(string: "https://itunes.apple.com/app/id991657053") else { return }
        UIApplication.shared.openURL(url)
        didReview = true
    }
    
    private static func noReviewAction() {
        neverShow = true
    }
}
