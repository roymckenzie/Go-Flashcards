//
//  ImageSelectionManager.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/31/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

import Photos

enum ImageSelectionManagerError: Error {
    case cancelled
    case mediaInfoMissingImage
    case sourceTypeNotFound
}

enum ImageSourceType: Int {
    case photoLibrary
    case camera
    case savedPhotosAlbum
    case googleImageSearch
}

private let ChooseSource = NSLocalizedString("Choose Source", comment: "Choose image source")
private let Camera = NSLocalizedString("Camera", comment: "Choose camera source")
private let PhotoLibrary = NSLocalizedString("Photo Library", comment: "Choose photo library source")
private let Cancel = NSLocalizedString("Cancel", comment: "Cancel image selection")

final class ImageSelectionManager: NSObject {
    
    let imagePicker = UIImagePickerController()
    
    let pickerPromise = Promise<UIImage>()
    
    func getPhoto(fromSource sourceType: ImageSourceType,
                  inViewController viewController: UIViewController) -> Promise<UIImage> {
        switch sourceType {
        case .camera, .photoLibrary, .savedPhotosAlbum:
            guard let pickerSource = UIImagePickerControllerSourceType(rawValue: sourceType.rawValue) else {
                pickerPromise.reject(ImageSelectionManagerError.sourceTypeNotFound)
                return pickerPromise
            }
            imagePicker.delegate = self
            imagePicker.sourceType = pickerSource
            viewController.present(imagePicker, animated: true, completion: nil)
        case .googleImageSearch:
            let vc = Storyboard.main.instantiateViewController(GoogleImagePickerViewController.self)
            vc.delegate = self
            viewController.present(vc, animated: true, completion: nil)
        }
        return pickerPromise
    }
    
    func chooseSourceType(inViewController viewController: UIViewController, sourceView: UIView) -> Promise<ImageSourceType> {
        let promise = Promise<ImageSourceType>()
        
        let alert = UIAlertController(title: ChooseSource, message: nil, preferredStyle: .actionSheet)
            alert.popoverPresentationController?.sourceView = sourceView
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: Camera, style: .default) { _ in
                promise.fulfill(.camera)
            }
            alert.addAction(cameraAction)
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let photoLibraryAction = UIAlertAction(title: PhotoLibrary, style: .default) { _ in
                promise.fulfill(.photoLibrary)
            }
            alert.addAction(photoLibraryAction)
        }
        
        let googleImagesAction = UIAlertAction(title: "Google Image Search", style: .default) { _ in
            promise.fulfill(.googleImageSearch)
        }
        alert.addAction(googleImagesAction)
        
        let cancelAction = UIAlertAction(title: Cancel, style: .cancel) { _ in
            promise.reject(ImageSelectionManagerError.cancelled)
        }
        
        alert.addAction(cancelAction)
        
        viewController.present(alert, animated: true, completion: nil)
        
        return promise
    }

}

extension ImageSelectionManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.pickerPromise.reject(ImageSelectionManagerError.cancelled)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            picker.dismiss(animated: true) { [weak self] in
                self?.pickerPromise.reject(ImageSelectionManagerError.mediaInfoMissingImage)
            }
            return
        }
        picker.dismiss(animated: true) { [weak self] in
            self?.pickerPromise.fulfill(image)
        }
    }
}

extension ImageSelectionManager: GoogleImagePickerViewControllerDelegate {
    
    func didCancel() {
        pickerPromise.reject(ImageSelectionManagerError.cancelled)
    }
    
    func didPick(image: UIImage) {
        pickerPromise.fulfill(image)
    }
}
