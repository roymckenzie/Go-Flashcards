//
//  UIImage+Extension.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/29/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import UIKit

enum ImageError: Error {
    case unableToConvertImageToData
    case unableToCreateImageFromContext
    case unableToGetImageUrlFromPath
    case unableToSaveImageLocally
}
extension UIImage {
    
    func saveToHomeDirectory(withRecordName recordName: String, key: String) throws -> String {
        
        let resizedImage = try resizeImageForStorage()
        let imageData = UIImageJPEGRepresentation(resizedImage, 8)
        
        guard let data = imageData else {
            throw ImageError.unableToConvertImageToData
        }
        
        let documentsUrl = try FileManager.default.url(for: .documentDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: false)
        
        let fileName = recordName + "-" + key + ".jpg"
        let fileUrl = documentsUrl.appendingPathComponent(fileName)

        if !FileManager.default.createFile(atPath: fileUrl.path, contents: data, attributes: nil) {
            throw ImageError.unableToSaveImageLocally
        }
        
        return fileName
    }
    
    func resizeImageForStorage(targetWidth: CGFloat = 500) throws -> UIImage {
        
        let currentWidth = size.width
        
        if currentWidth <= targetWidth {
            return self
        }
        
        let scale = targetWidth / currentWidth
        
        let newHeight = size.height * scale
        let newWidth = currentWidth * scale
        
        let newSize = CGSize(width: newWidth, height: newHeight)
        let drawingRect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContext(newSize)

        draw(in: drawingRect)
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
            throw ImageError.unableToCreateImageFromContext
        }
        UIGraphicsEndImageContext()
        return newImage
    }
}
