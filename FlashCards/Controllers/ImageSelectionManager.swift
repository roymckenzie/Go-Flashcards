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
}

final class ImageSelectionManager: NSObject {
    
    let imagePicker = UIImagePickerController()
    
    let pickerPromise = Promise<UIImage>()
    
    func getPhoto(fromSource sourceType: UIImagePickerControllerSourceType,
                  inViewController viewController: UIViewController) -> Promise<UIImage> {
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        viewController.present(imagePicker, animated: true, completion: nil)
        return pickerPromise
    }
    
    func chooseSourceType(inViewController viewController: UIViewController, sourceView: UIView) -> Promise<UIImagePickerControllerSourceType> {
        let promise = Promise<UIImagePickerControllerSourceType>()
        
        let alert = UIAlertController(title: "Choose Source", message: nil, preferredStyle: .actionSheet)
            alert.popoverPresentationController?.sourceView = sourceView
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            promise.fulfill(.camera)
        }
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
            promise.fulfill(.photoLibrary)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            promise.reject(ImageSelectionManagerError.cancelled)
        }
        
        alert.addAction(cameraAction)
        alert.addAction(photoLibraryAction)
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
