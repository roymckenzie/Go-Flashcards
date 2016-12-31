//
//  FlashCardViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift

class FlashCardViewController: UIViewController {
    
    @IBOutlet weak var cardViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cardViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var backView: UIView!
    
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var frontContainerView: UIView!
    @IBOutlet weak var frontTextView: PlaceholderTextView!
    @IBOutlet weak var frontImageView: UIImageView!
    @IBOutlet weak var frontTextViewCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var backTextView: PlaceholderTextView!
    @IBOutlet weak var backImageView: UIImageView!
    @IBOutlet weak var backTextViewCenterYConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var pageControl: UIPageControl!
    var stack: Stack!
    var card: Card!
    
    let frontDismissGesture = UITapGestureRecognizer()
    let backDismissGesture = UITapGestureRecognizer()
    
    // For animating status bar appearance
    var statusBarHidden = false
    
    let imageSelectionManager = ImageSelectionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if card != nil {
            frontTextView.text = card.frontText
            backTextView.text = card.backText
            frontImageView.image = card.frontImage
            backImageView.image = card.backImage
            let _ = [frontTextView,backTextView].flatMap(textViewDidChange)
        } else {
            card = Card()
        }
        
        let cardSize = Card.cardSizeFor(view: view)
        
        cardViewHeightConstraint.constant = cardSize.height
        cardViewWidthConstraint.constant = cardSize.width
        
        view.layoutIfNeeded()
        
        frontView.round(corners: [.allCorners], radius: 8)
        backView.round(corners: [.allCorners], radius: 8)
        
        pageControl.addTarget(self, action: #selector(changePage), for: .valueChanged)
        frontDismissGesture.addTarget(self, action: #selector(dismissKeyboard))
        backDismissGesture.addTarget(self, action: #selector(dismissKeyboard))
        frontView.addGestureRecognizer(frontDismissGesture)
        backView.addGestureRecognizer(backDismissGesture)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func changePage() {
        var contentOffset = CGPoint.zero
        if scrollView.contentOffset.x > 0 {
            contentOffset.x = 0
        } else {
            contentOffset.x = scrollView.contentSize.width/2
        }
        
        scrollView.setContentOffset(contentOffset, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addKeyboardListeners() { [weak self] keyboardHeight in
            
            self?.frontTextViewCenterYConstraint.constant = -(keyboardHeight/2)
            self?.backTextViewCenterYConstraint.constant = -(keyboardHeight/2)
            
            UIView.animate(withDuration: 0.2) {
                self?.view.layoutIfNeeded()
            }
        }

        statusBarHidden = true
        
        UIView.animate(withDuration: 0.33) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        removeKeyboardListeners()
    }
    
    @IBAction func pickFrontImage(_ sender: UIButton) {
        guard let frontImageView = self.frontImageView else { return }
        if frontImageView.image != nil {
            showDeleteImageAlert()
                .then { [weak self] delete in
                    if delete {
                        frontImageView.image = nil
                    } else {
                        self?.pickImageFor(imageView: frontImageView, sourceView: sender)
                    }
                }
            return
        }
        pickImageFor(imageView: frontImageView, sourceView: sender)
    }
    
    private func showDeleteImageAlert() -> Promise<Bool> {
        return Promise<Bool>() { [weak self] fulfill, reject in
            let alertController = UIAlertController(title: "Change image?", message: nil, preferredStyle: .actionSheet)
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                fulfill(true)
            }
            let replaceAction = UIAlertAction(title: "Replace", style: .default) { _ in
                fulfill(false)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(deleteAction)
            alertController.addAction(replaceAction)
            alertController.addAction(cancelAction)
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func pickBackImage(_ sender: UIButton) {
        guard let backImageView = backImageView else { return }
        if backImageView.image != nil {
            showDeleteImageAlert()
                .then { [weak self] delete in
                    if delete {
                        backImageView.image = nil
                    } else {
                        self?.pickImageFor(imageView: backImageView, sourceView: sender)
                    }
                }
            return
        }
        pickImageFor(imageView: backImageView, sourceView: sender)
    }
    
    func pickImageFor(imageView: UIImageView, sourceView: UIView) {
        
        let imageSelectionManager = self.imageSelectionManager
        
        ImagePermissionManager
            .requestCameraLibraryPermission()
            .then {
                return ImagePermissionManager.requestPhotoLibraryPermission()
            }
            .then {
                return imageSelectionManager.chooseSourceType(inViewController: self, sourceView: sourceView)
            }
            .then { sourceType in
                return imageSelectionManager.getPhoto(fromSource: sourceType, inViewController: self)
            }
            .then { image in
                imageView.image = image
            }
            .catch { [weak self] error in
                switch error {
                case ImageSelectionManagerError.cancelled:
                    break
                case ImageSelectionManagerError.mediaInfoMissingImage:
                    self?.showAlert(title: "Uh oh", error: error)
                case ImagePermissionError.cameraAccessDeniedOrRestricted:
                    ImagePermissionManager.showSettingsAlert(forPermissionType: "Camera", inViewController: self!)
                case ImagePermissionError.photoLibraryAccessDeniedOrRestricted:
                    ImagePermissionManager.showSettingsAlert(forPermissionType: "Photo Library", inViewController: self!)
                default:
                    break
                }
            }
    }
    
    @IBAction func deleteCard(_ sender: Any) {
        showAlert(title: "Delete card?",
                  message: nil,
                  firstActionTitle: "Cancel",
                  secondActionTitle: "Delete",
                  secondActionStyle: .destructive) { [weak self] in
                    
            guard let card = self?.card else { return }
            
            let realm = try! Realm()
            
            try? realm.write {
                realm.delete(card)
            }
            
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func saveCard(_ sender: AnyObject) {
        view.endEditing(true)
        
        let realm = try? Realm()
        
        try? realm?.write {
            if let stack = card.stack, !stack.cards.contains(card) {
                stack.cards.append(card)
            } else if !stack.cards.contains(card) {
                stack.cards.append(card)
            }
            if let imagePath = try? frontImageView.image?.saveToHomeDirectory(withRecordName: card.id, key: "frontImage") {
                card.frontImagePath = imagePath
            }
            if let imagePath = try? backImageView.image?.saveToHomeDirectory(withRecordName: card.id, key: "backImage") {
                card.backImagePath = imagePath
            }
            card.frontText = frontTextView.text
            card.backText = backTextView.text
            card.modified = Date()
            card.order = Double(stack?.cards.count ?? 0)
            realm?.add(card, update: true)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dismiss(_ sender: Any) {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

// MARK:- UITextViewDelegate
extension FlashCardViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        guard let textView = textView as? PlaceholderTextView else { return }
        if textView.text.characters.count > 0 {
            textView.placeholderLabel?.isHidden = true
        } else {
            textView.placeholderLabel?.isHidden = false
        }
    }
}

// MARK:- KeyboardAvoidable
extension FlashCardViewController: KeyboardAvoidable {
    
    var layoutConstraintsToAdjust: [NSLayoutConstraint] {
        return []
    }
}

// MARK:- ScrollViewDelegate
extension FlashCardViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x > 0 {
            pageControl.currentPage = 1
        } else {
            pageControl.currentPage = 0
        }
    }
}


final class PlaceholderTextView: UITextView {
    @IBOutlet weak var placeholderLabel: UILabel?
}
