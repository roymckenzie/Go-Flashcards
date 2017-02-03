//
//  QuizletStackViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/22/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit
import RealmSwift
import WebImage
import CloudKit
import SwiftyStoreKit

private let DownloadOptions = NSLocalizedString("Download options",
                                                comment: "Alert title for download")

private let SaveToMyStacks = NSLocalizedString("Save to My Stacks",
                                               comment: "Save Sack action")

private let SaveCardsToExistingStack = NSLocalizedString("Save Cards to existing Stack",
                                                         comment: "Save cards action")

private let Cancel = NSLocalizedString("Cancel",
                                       comment: "Cancel action")

private let CouldNotVerifySubscription = NSLocalizedString("Could not verify subscription",
                                                           comment: "Alert title")

private let Updated = NSLocalizedString("Updated: %@",
                                        comment: "Stack updated")

private let CardCount = NSLocalizedString("%i cards",
                                          comment: "Card count")

private let Language = NSLocalizedString("Language: %@/%@",
                                        comment: "Language")

private let IncludesImages = NSLocalizedString("Includes images",
                                               comment: "Stack includes images")

private let SavingStack = NSLocalizedString("Saving Stack",
                                            comment: "Loading view text")


final class QuizletStackViewController: UIViewController {
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long
        return df
    }()
    
    lazy var collectionViewController: QuizletCardsCollectionViewController = {
        return QuizletCardsCollectionViewController(collectionView: self.collectionView)
    }()
    
    var stack: QuizletStack!
    
    // MARK:- Outlets
    @IBOutlet weak var updatedLabel: UILabel!
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var cardCountLabel: UILabel!
    @IBOutlet weak var includesImages: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK:- Actions
    @IBAction func download() {
        showDownloadOptions()
    }
    
    private func showDownloadOptions() {
        let alert = UIAlertController(title: DownloadOptions,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        alert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        let copyStackAction = UIAlertAction(title: SaveToMyStacks,
                                            style: .default)
        { [weak self] _ in
            guard let _self = self else { return }
            _self.checkPurchase(completion: _self.purchaseSave)
        }
        alert.addAction(copyStackAction)
        
        let copyCardsAction = UIAlertAction(title: SaveCardsToExistingStack,
                                            style: .default)
        { [weak self] _ in
            guard let _self = self else { return }
            _self.checkPurchase(completion: _self.saveCardsToStack)
        }
        alert.addAction(copyCardsAction)
        
        let cancelAction = UIAlertAction(title: Cancel,
                                         style: .cancel,
                                         handler: nil)
        alert.addAction(cancelAction)
        
        present(alert,
                animated: true,
                completion: nil)
    }
    
    private func purchaseSave() {
        save()
    }
    
    private func checkPurchase(completion: @escaping () -> Void) {
        let loadingView = LoadingView()
        loadingView.show()
        PurchaseController.default
            .verifyActiveSubscription()
            .then { [weak self] active in
                if active {
                    completion()
                    return
                }
                self?.showPurchaseOptions(then: completion)
                return
            }
            .always {
                loadingView.hide()
            }
            .catch { [weak self] error in
                self?.showAlert(title: CouldNotVerifySubscription, error: error)
                debugPrint("Error checking purchases: \(error.localizedDescription)")
            }
    }
    
    private func showPurchaseOptions(then completion: @escaping ()-> Void) {
        performSegue(withIdentifier: "showPurchaseView", sender: completion)
    }
    
    // MARK:- Override supers
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(stack != nil, "Stack was nil in \(self.description)")
        
        prepareView()
        
        QuizletSearchController.get(stackId: stack.id)
            .then { [weak self] stack in
                self?.stack = stack
                self?.prepareView()
            }
            .catch { error in
                debugPrint("Could not fetch stack from Quizlet: \(error.localizedDescription)")
            }
    }
    
    private func prepareView() {
        title = stack.name
        
        let updatedDate = dateFormatter.string(from: stack.modifiedDate)
        let updatedText = String(format: Updated, arguments: [updatedDate])
        let cardCountText = String(format: CardCount, arguments: [stack.cardCount])
        
        updatedLabel.text = updatedText
        cardCountLabel.text = cardCountText
        if let frontLanguage = stack.frontLanguage,
            let backLanguage = stack.backLanguage {
            let languageText = String(format: Language, arguments: [frontLanguage,backLanguage])
            languageLabel.text = languageText
        }
        includesImages.text = stack.hasImages ? IncludesImages : nil
        collectionViewController.dataSource = stack.cards
    }
    
    private func saveCardsToStack() {
        performSegue(withIdentifier: "showMyStacks", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.destination {
        case let vc as MyStacksCopyViewController:
            vc.didSelectItem = { [weak self] stack, _ in
                vc.dismiss(animated: true) {
                    self?.save(to: stack)
                }
            }
        case let vc as PurchaseViewController:
            vc.completion = sender as? (() -> Void)
        default: break
        }
    }
    
    private func save(to existingStack: Stack? = nil) {
        
        let loadingView = LoadingView()
        loadingView.show(withMessage: SavingStack)
        
        let newStack: Stack
        
        if let stack = existingStack {
            newStack = stack
        } else {
            newStack = Stack(stack: stack)
        }
        
        let realm = try! Realm()

        let downloadPromise = Promise<Void>()
        
        downloadPromise
            .then { [weak self] in
                guard let cards = self?.stack.cards.flatMap(Card.init) else { return }
                try? realm.write {
                    newStack.cards.append(objectsIn: cards)
                    realm.add(newStack)
                }
                self?.tabBarController?.selectedIndex = 0
            }
            .catch { error in
                debugPrint("Error saving cards: \(error.localizedDescription)")
            }
            .always {
                loadingView.hide()
            }
        
        var totalWithImageCount = stack.cards.filter { $0.largeBackImageUrl != nil }.count

        for index in 0..<stack.cards.count {
            guard let _ = stack.cards[index].largeBackImageUrl else {
                if totalWithImageCount == 0 {
                    downloadPromise.fulfill()
                }
                continue
            }
            SDWebImageDownloader
                .shared()
                .downloadImage(with: stack.cards[index].largeBackImageUrl!, options: .highPriority, progress: nil) { [weak self] image, data, error, _ in
                guard let _self = self else {
                    return
                }
                if let error = error {
                    downloadPromise.reject(error)
                    return
                }
                guard let image = image else {
                    return
                }
                do {
                    _self.stack.cards[index].localImagePath = try image.saveToHomeDirectory(withRecordName: "\(_self.stack.cards[index].id)", key: "backImage")
                } catch {
                    downloadPromise.reject(error)
                }
                totalWithImageCount -= 1

                    if totalWithImageCount == 0 {
                    downloadPromise.fulfill()
                }
            }
        }
    }
}
