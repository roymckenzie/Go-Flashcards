//
//  GoogleImagePickerViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/9/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit
import SDWebImage

final class GoogleImagePickerViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!

    var delegate: GoogleImagePickerViewControllerDelegate?
    
    // To store, and refer to quickly, cached images from Google Search
    var viewCache = [URL: UIImage]()
    
    lazy var fetchController: GoogleImageFetchController = {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        return GoogleImageFetchController(session: session)
    }()
    
    fileprivate var dataSource = [URL]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    deinit {
        print("[GoogleImagePickerViewController] deinit")
    }
    
    @IBAction func done(_ sender: Any) {
        view.endEditing(true)
        delegate?.didCancel()
        dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.registerNib(GoogleImageCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        addKeyboardListeners()
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        removeKeyboardListeners()
    }
    
    func performSearch() {
        guard let query = searchBar.text, query.characters.count > 0 else { return }
        viewCache.removeAll()
        dataSource.removeAll()
        collectionView.reloadData()
        fetchController
            .fetchResults(for: query, filetype: "jpg", imageSize: .medium, index: 0)
            .then { [weak self] result in
                self?.dataSource = result.results
            }
            .catch { error in
                NSLog("Error fetching images: \(error.localizedDescription)")
            }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}

extension GoogleImagePickerViewController: KeyboardAvoidable {
    
    var layoutConstraintsToAdjust: [NSLayoutConstraint] {
        return [collectionViewBottomConstraint]
    }
}

extension GoogleImagePickerViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: nil, afterDelay: 0.75)
    }
}

extension GoogleImagePickerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withClass: GoogleImageCell.self, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let imageURL = dataSource[indexPath.row]
        
        guard let imageSize = viewCache[imageURL]?.size else {
            return CGSize(width: (collectionView.frame.width-2) / 2, height: 100)
        }
        
        let newWidth = (collectionView.frame.width-2) / 2
        let ratio = newWidth/imageSize.width
        let height = imageSize.height * ratio
        return CGSize(width: newWidth, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let url = dataSource[indexPath.item]
        switch cell {
        case let cell as GoogleImageCell:
            if let image = viewCache[url] {
                cell.imageView.image = image
                return
            }
            cell.imageView.sd_setImage(with: url) { [weak self] image, _, _, _ in
                if let image = image {
                    self?.viewCache[url] = image
                }
                collectionView.invalidateIntrinsicContentSize()
                collectionView.collectionViewLayout.invalidateLayout()
            }
        default: break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let image = (collectionView.cellForItem(at: indexPath) as? GoogleImageCell)?.imageView.image else { return }
        dismiss(animated: true) { [weak self] in
            self?.delegate?.didPick(image: image)
        }
    }
}

protocol GoogleImagePickerViewControllerDelegate {
    func didPick(image: UIImage)
    func didCancel()
}
