//
//  UIViewController+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/23/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showAlert(title: String,
                   message: String?,
                   firstActionTitle: String? = "OK",
                   secondActionTitle: String? = nil,
                   secondActionStyle: UIAlertActionStyle = .default,
                   secondActionCompletion: (()->Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: firstActionTitle, style: .default, handler: nil)
        alert.addAction(okAction)
        if let secondActionTitle = secondActionTitle {
            let secondAction = UIAlertAction(title: secondActionTitle, style: secondActionStyle) { _ in
                secondActionCompletion?()
            }
            alert.addAction(secondAction)
        }
        present(alert, animated: true, completion: nil)
    }
    
    func showAlert(title: String, error: Error) {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}
