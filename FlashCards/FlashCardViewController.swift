//
//  FlashCardViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 5/2/15.
//  Copyright (c) 2015 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift

private let Delete = NSLocalizedString("Delete", comment: "Delete button")
private let Cancel = NSLocalizedString("Cancel", comment: "Cancel button")
private let Replace = NSLocalizedString("Replace", comment: "Replace button")
private let ChangeImage = NSLocalizedString("Change image?", comment: "Change image alert title")
private let Camera = NSLocalizedString("Camera", comment: "Camera source option")
private let PhotoLibrary = NSLocalizedString("Photo Library", comment: "Photo Library source option")
private let DeleteCard = NSLocalizedString("Delete card?", comment: "Delete card alert title")
private let UhOh = NSLocalizedString("Uh oh", comment: "Uh oh problem alert title")

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
    @IBOutlet weak var frontImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var backTextView: PlaceholderTextView!
    @IBOutlet weak var backImageView: UIImageView!
    @IBOutlet weak var backTextViewCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var backImageViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sideControl: UISegmentedControl!
    var stack: Stack!
    var card: Card!
    
    let frontDismissGesture = UITapGestureRecognizer()
    let backDismissGesture = UITapGestureRecognizer()
    
    // For animating status bar appearance
    var statusBarHidden = false
    
    let imageSelectionManager = ImageSelectionManager()
    
    var frontImageViewChanged = false
    var backImageViewChanged = false
    
    var frontImage: UIImage? {
        didSet {
            frontImageView.image = frontImage
            layoutViews()
        }
    }
    
    var backImage: UIImage? {
        didSet {
            backImageView.image = backImage
            layoutViews()
        }
    }
    
    var frontText: String? {
        didSet {
            frontTextView.text = frontText
            layoutViews()
        }
    }
    
    var backText: String? {
        didSet {
            backTextView.text = backText
            layoutViews()
        }
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if card != nil {
            frontText = card.frontText
            backText = card.backText
            frontImage = card.frontImage
            backImage = card.backImage
            let _ = [frontTextView,backTextView].flatMap(textViewDidChange)
            if stack == nil {
                stack = card.stack
            }
        } else {
            card = Card()
        }
        
        assert(stack != nil, "STACK IS NIL in FlashCardViewController.swift")
        
        let doneInputAccessoryView = UIToolbar.doneInputAccessoryView
        doneInputAccessoryView.doneButton.target = self
        doneInputAccessoryView.doneButton.action = #selector(dismissKeyboard)
        frontTextView.inputAccessoryView = doneInputAccessoryView
        backTextView.inputAccessoryView = doneInputAccessoryView
        
        let cardSize = CardUI.editCardSizeFor(view: frontContainerView)
        
        cardViewHeightConstraint.constant = cardSize.height
        cardViewWidthConstraint.constant = cardSize.width
        
        view.layoutIfNeeded()
        
        frontView.round(corners: [.allCorners], radius: 8)
        backView.round(corners: [.allCorners], radius: 8)
        
        sideControl.addTarget(self, action: #selector(changePage), for: .valueChanged)
        frontDismissGesture.addTarget(self, action: #selector(dismissKeyboard))
        backDismissGesture.addTarget(self, action: #selector(dismissKeyboard))
        frontView.addGestureRecognizer(frontDismissGesture)
        backView.addGestureRecognizer(backDismissGesture)
    }
    
    @IBAction func changePage(_ sender: UISegmentedControl) {
        var contentOffset = CGPoint.zero
        if sender.selectedSegmentIndex == 0 {
            contentOffset.x = 0
        } else {
            contentOffset.x = scrollView.contentSize.width/2
        }
        
        scrollView.setContentOffset(contentOffset, animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addKeyboardListeners() { [weak self] keyboardHeight in
            guard let _self = self else { return }
            
            if keyboardHeight == 0 {
                self?.layoutViews()
                return
            }
            let textLabelConstraintConstant = _self.frontView.frame.height / 4
            self?.frontTextViewCenterYConstraint.constant = -textLabelConstraintConstant
            self?.backTextViewCenterYConstraint.constant = -textLabelConstraintConstant
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
            showDeleteImageAlert(fromButton: sender)
                .then { [weak self] delete in
                    if delete {
                        self?.frontImage = nil
                        self?.frontImageViewChanged = true
                    } else {
                        self?.pickImageFor(imageView: frontImageView, sourceView: sender)
                    }
                }
            return
        }
        pickImageFor(imageView: frontImageView, sourceView: sender)
    }

    private func showDeleteImageAlert(fromButton button: UIButton) -> Promise<Bool> {
        return Promise<Bool>() { [weak self] fulfill, reject in
            let alertController = UIAlertController(title: ChangeImage, message: nil, preferredStyle: .actionSheet)
            alertController.popoverPresentationController?.sourceView = button
            let deleteAction = UIAlertAction(title: Delete, style: .destructive) { _ in
                fulfill(true)
            }
            let replaceAction = UIAlertAction(title: Replace, style: .default) { _ in
                fulfill(false)
            }
            let cancelAction = UIAlertAction(title: Cancel, style: .cancel, handler: nil)
            alertController.addAction(deleteAction)
            alertController.addAction(replaceAction)
            alertController.addAction(cancelAction)
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func pickBackImage(_ sender: UIButton) {
        guard let backImageView = backImageView else { return }
        if backImageView.image != nil {
            showDeleteImageAlert(fromButton: sender)
                .then { [weak self] delete in
                    if delete {
                        self?.backImage = nil
                        self?.backImageViewChanged = true
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
            .then { [weak self] image in
                
                switch imageView {
                case (self?.frontImageView)!:
                    self?.frontImage = image
                    self?.frontImageViewChanged = true
                case (self?.backImageView)!:
                    self?.backImage = image
                    self?.backImageViewChanged = true
                default: break
                }
            }
            .catch { [weak self] error in
                switch error {
                case ImageSelectionManagerError.cancelled:
                    break
                case ImageSelectionManagerError.mediaInfoMissingImage:
                    self?.showAlert(title: UhOh, error: error)
                case ImagePermissionError.cameraAccessDeniedOrRestricted:
                    ImagePermissionManager.showSettingsAlert(forPermissionType: Camera, inViewController: self!)
                case ImagePermissionError.photoLibraryAccessDeniedOrRestricted:
                    ImagePermissionManager.showSettingsAlert(forPermissionType: PhotoLibrary, inViewController: self!)
                default:
                    break
                }
            }
    }
    
    @IBAction func deleteCard(_ sender: Any) {
        showAlert(title: DeleteCard,
                  message: nil,
                  firstActionTitle: Cancel,
                  secondActionTitle: Delete,
                  secondActionStyle: .destructive) { [weak self] in
                    
            guard let card = self?.card else { return }
            
            let realm = try! Realm()
            
            let date = Date()
            try? realm.write {
                card.deleted = date
                card.modified = date
            }
            
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func saveCard(_ sender: AnyObject) {
        view.endEditing(true)
        
        let realm = try! Realm()
        
        try? realm.write {
            if !stack.cards.contains(card) {
                stack.cards.append(card)
            }
            if frontImageViewChanged, let imagePath = try? frontImageView.image?.saveToHomeDirectory(withRecordName: card.id, key: "frontImage") {
                card.frontImageUpdated = true
                card.frontImagePath = imagePath
            }
            if backImageViewChanged, let imagePath = try? backImageView.image?.saveToHomeDirectory(withRecordName: card.id, key: "backImage") {
                card.backImageUpdated = true
                card.backImagePath = imagePath
            }
            card.frontText = frontTextView.text
            card.backText = backTextView.text
            card.modified = Date()
            card.recordOwnerName = stack.recordOwnerName // So things sync with CloudKit correctly for sharing
            stack.preferences?.modified = Date()
            realm.add(card, update: true)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        layoutViews()
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
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let cardSize = CardUI.cardSizeFor(view: scrollView)
        
        cardViewHeightConstraint.constant = cardSize.height
        cardViewWidthConstraint.constant = cardSize.width
        
        view.layoutIfNeeded()
    }

    func layoutViews() {
        
        let imageConstraintConstant = frontView.frame.height / 2
        let textLabelConstraintConstant = frontView.frame.height / 4

        if let _ = frontImage, let frontText = frontText, frontText.characters.count > 0 {
            frontImageViewTopConstraint.constant = imageConstraintConstant
            frontTextViewCenterYConstraint.constant = -textLabelConstraintConstant
        } else {
            frontImageViewTopConstraint.constant = 0
            if !frontTextView.isFirstResponder {
                frontTextViewCenterYConstraint.constant = 0
            }
        }

        if let _ = backImage, let backText = backText, backText.characters.count > 0 {
            backImageViewTopConstraint.constant = imageConstraintConstant
            backTextViewCenterYConstraint.constant = -textLabelConstraintConstant
        } else {
            backImageViewTopConstraint.constant = 0
            if !backTextView.isFirstResponder {
                backTextViewCenterYConstraint.constant = 0
            }
        }

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
        
        switch textView {
        case frontTextView:
            frontText = textView.text
        case backTextView:
            backText = textView.text
        default: break
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
            sideControl.selectedSegmentIndex = 1
        } else {
            sideControl.selectedSegmentIndex = 0
        }
    }
}


final class PlaceholderTextView: UITextView {
    @IBOutlet weak var placeholderLabel: UILabel?
}
