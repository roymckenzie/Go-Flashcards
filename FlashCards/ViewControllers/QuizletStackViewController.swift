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
        let alert = UIAlertController(title: "Download options",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        let copyStackAction = UIAlertAction(title: "Save to My Stacks",
                                            style: .default)
        { [weak self] _ in
            self?.save()
        }
        alert.addAction(copyStackAction)
        
        let copyCardsAction = UIAlertAction(title: "Save Cards to existing Stack",
                                            style: .default)
        { [weak self] _ in
            self?.saveCardsToStack()
        }
        alert.addAction(copyCardsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: nil)
        alert.addAction(cancelAction)
        
        present(alert,
                animated: true,
                completion: nil)
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
                NSLog("Could not fetch stack from Quizlet: \(error.localizedDescription)")
            }
    }
    
    private func prepareView() {
        title = stack.name
        
        updatedLabel.text = "Updated: \(dateFormatter.string(from: stack.modifiedDate))"
        cardCountLabel.text = "\(stack.cardCount) cards"
        if let frontLanguage = stack.frontLanguage,
            let backLanguage = stack.backLanguage {
            languageLabel.text = "Language: \(frontLanguage)/\(backLanguage)"
        }
        includesImages.text = stack.hasImages ? "Includes images" : nil
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
        default: break
        }
    }
    
    private func save(to existingStack: Stack? = nil) {
        
        let loadingView = LoadingView()
        loadingView.show(withMessage: "Saving Stack")
        
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
                NSLog("Error saving cards: \(error.localizedDescription)")
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

final class QuizletCardsCollectionViewController: NSObject {
    
    weak var collectionView: UICollectionView!
    
    var dataSource = [QuizletCard]() {
        didSet { collectionView.reloadData() }
    }
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        
        collectionView.registerNib(CardCell.self)

        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

private let CardSpacing: CGFloat = 15
extension QuizletCardsCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let rowCount: CGFloat
        
        // width, height
        switch (collectionView.traitCollection.horizontalSizeClass, collectionView.traitCollection.verticalSizeClass) {
        case (.regular, .regular):
            rowCount = 5
        case (.compact, .regular):
            rowCount = 3
        case (.compact, .compact):
            rowCount = 5
        default:
            rowCount = 1
        }
        
        let totalVerticalSpacing = ((rowCount-1)*CardSpacing) + (CardSpacing*2)
        let verticalSpacingAffordance = totalVerticalSpacing / rowCount
        let width = (collectionView.frame.size.width / rowCount) - verticalSpacingAffordance
        let height = width * 1.333
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return CardSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CardSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch section {
        case 0:
            return UIEdgeInsets(top: CardSpacing, left: CardSpacing, bottom: CardSpacing, right: CardSpacing)
        default:
            return UIEdgeInsets(top: 0, left: CardSpacing, bottom: CardSpacing, right: CardSpacing)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        setCellContentsFor(indexPath: indexPath, cell: cell)
    }
    
    func setCellContentsFor(indexPath: IndexPath, cell: UICollectionViewCell) {
        let cell = cell as? CardCell
        let card = dataSource[indexPath.row]
        cell?.frontText = card.frontText
        if let backImageUrl = card.backImageUrl {
            cell?.setImageWith(url: backImageUrl)
        }
    }
}

extension QuizletCardsCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withClass: CardCell.self, for: indexPath)
    }
}
