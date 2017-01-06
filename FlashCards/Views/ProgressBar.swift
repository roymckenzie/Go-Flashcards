//
//  ProgressBar.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/3/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit

final class ProgressBar: UIControl {
    
    private let progressView = UIView()
    
    private var total: CGFloat = 1
    private var progress: CGFloat = 0
    
    @IBInspectable var progressColor: UIColor = .green
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    private func setup() {
        layer.cornerRadius = self.frame.height/2
        clipsToBounds = true
        progressView.backgroundColor = progressColor
        progressView.layer.cornerRadius = self.frame.height/2
        addSubview(progressView)
        
    }
    
    func setProgress(_ progress: CGFloat, of total: CGFloat) {
        self.total = total
        self.progress = progress
        
        let progressPercent = progress/total
        
        let progressViewWidth = frame.width*progressPercent
        
        UIView.animate(withDuration: 0.2) {
            self.progressView.frame.size.width = progressViewWidth
            self.progressView.frame.size.height = self.frame.size.height
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        progressView.layer.cornerRadius = frame.height/2
        layer.cornerRadius = frame.height/2
        setProgress(progress, of: total)
    }
}
