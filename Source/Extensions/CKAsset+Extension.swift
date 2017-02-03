//
//  CKAsset+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/29/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import CloudKit
import UIKit

extension CKAsset {
    
    var image: UIImage? {
        guard let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) else { return nil }
        return image
    }
}
