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

private let Cancel = NSLocalizedString("Cancel", comment: "Cancel button")
private let Settings = NSLocalizedString("Settings", comment: "Settings button")
private let GoToSettings = NSLocalizedString("Go to Settings", comment: "Go to settings alert title")

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
        let localized = NSLocalizedString("You'll need to enable %@ access in settings.", comment: "Go to settings to enable")
        let localizedWithType = String(format: localized, arguments: [permissionType])
        viewController.showAlert(title: GoToSettings, message: localizedWithType, firstActionTitle: Cancel, secondActionTitle: Settings, secondActionStyle: .default) {
         
            if let url = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(url)
            }
        }
    }
}
