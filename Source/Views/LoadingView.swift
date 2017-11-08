//
//  LoadingView.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/18/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

/// Loading View
final class LoadingView: UIView {
    
    private let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
    private lazy var actionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.adjustsFontSizeToFitWidth = true
        self.frame.size.height += 10
        self.addSubview(label)
        label.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
        label.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10).isActive = true
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        return label
    }()
    
    private var appWindow: UIWindow? {
        return UIApplication.shared.keyWindow
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    convenience init(labelText: String) {
        self.init(frame: .zero)
        actionLabel.text = labelText
    }
    
    private func setup() {
        // Background and corners
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        layer.cornerRadius = 14
        
        // Frame
        frame.size.width = 100
        frame.size.height = 100
        
        // Activity indicator setup
        addSubview(activityIndicatorView)
        activityIndicatorView.center = center
    }
    
    /// Start animating indicator view
    func startAnimating() {
        activityIndicatorView.startAnimating()
    }
    
    /// Stop animating indicator view
    func stopAnimating() {
        activityIndicatorView.stopAnimating()
    }
    
    func show(withMessage message: String? = nil) {
        actionLabel.text = message
        startAnimating()
        center = appWindow?.center ?? CGPoint.zero
        appWindow?.rootViewController?.view.addSubview(self)
    }
    
    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.stopAnimating()
            self?.removeFromSuperview()
        }
    }
}
