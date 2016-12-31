//
//  ImagePermissionManager.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/30/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Foundation
import Photos

enum ImagePermissionError: Error {
    case photoLibraryAccessDeniedOrRestricted
    case cameraAccessDeniedOrRestricted
}

struct ImagePermissionManager {
    
    static func requestPhotoLibraryPermission() -> Promise<Void> {
        return Promise<Void>(work: { fulfill, reject in
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized:
                fulfill()
            case .denied, .restricted:
                reject(ImagePermissionError.photoLibraryAccessDeniedOrRestricted)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        fulfill()
                    } else {
                        reject(ImagePermissionError.photoLibraryAccessDeniedOrRestricted)
                    }
                }
            }
        })
    }
    
    static func requestCameraLibraryPermission() -> Promise<Void> {
        return Promise<Void>(work: { fulfill, reject in
            
            switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
            case .authorized:
                fulfill()
            case .denied, .restricted:
                reject(ImagePermissionError.cameraAccessDeniedOrRestricted)
            case.notDetermined:
                AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { authorized in
                    if authorized {
                        fulfill()
                    } else {
                        reject(ImagePermissionError.cameraAccessDeniedOrRestricted)
                    }
                }
            }
        })
    }
    
    static func showSettingsAlert(forPermissionType permissionType: String,
                                  inViewController viewController: UIViewController) {
        viewController.showAlert(title: "Go To Settings", message: "You'll need to enable \(permissionType) access in settings.", firstActionTitle: "Cancel", secondActionTitle: "Settings", secondActionStyle: .default) {
         
            if let url = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(url)
            }
        }
    }
}
