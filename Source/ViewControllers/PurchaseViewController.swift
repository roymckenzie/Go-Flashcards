//
//  PurchaseViewController.swift
//  FlashCards
//
//  Created by Roy McKenzie on 1/27/17.
//  Copyright © 2017 Roy McKenzie. All rights reserved.
//

import UIKit
import StoreKit

private let CouldNotGetSubscriptionOptions = NSLocalizedString("Could not get subscription options",
                                                               comment: "Error alert title")
private let CouldNotPurchaseSubscription = NSLocalizedString("Could not purchase subscription",
                                                             comment: "Error alert title")
private let Purchasing = NSLocalizedString("Purchasing...",
                                           comment: "Loading view message")

final class PurchaseViewController: UIViewController {
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var accessButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightContraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    lazy var tableController: PurchaseOptionsTableController = {
        return PurchaseOptionsTableController(tableView: self.tableView)
    }()
    
    var completion: (()->Void)?
    
    var currentlySelectedProduct: SKProduct? {
        didSet {
            accessButton.isEnabled = currentlySelectedProduct != nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableController.didSelectRow = { [weak self] product, _ in
            self?.currentlySelectedProduct = product
        }
        
        tableController.updateHeight = { [weak self] in
            self?.tableViewHeightContraint.constant = self?.tableView.contentSize.height ?? 0
        }
        
        PurchaseController.default.getProducts()
            .then { [weak self] products in
                self?.tableController.dataSource.append(contentsOf: products)
                self?.tableController.reloadData()
                self?.updateView()
            }
            .catch { [weak self] error in
                self?.showAlert(title: CouldNotGetSubscriptionOptions, error: error)
                debugPrint("Could not fetch products: \(error.localizedDescription)")
        }
    }
    
    func updateView() {
        descriptionLabel.text = tableController.dataSource.first?.localizedDescription
    }
    
    @IBAction func notNow() {
        dismiss(animated: true,
                completion: nil)
    }
    
    @IBAction func purchase() {
        let loadingView = LoadingView()
        loadingView.show(withMessage: Purchasing)
        guard let productID = currentlySelectedProduct?.productIdentifier,
            let subscription = InAppPurchaseSubscription(rawValue: productID) else { return }
        PurchaseController.default
            .purchase(subscription)
            .then { [weak self] purchased in
                if purchased {
                    self?.dismiss(animated: true,
                                  completion: self?.completion)
                }
            }
            .always {
                loadingView.hide()
            }
            .catch { [weak self] error in
                self?.showAlert(title: CouldNotPurchaseSubscription, error: error)
                debugPrint("Could not complete purchase: \(error.localizedDescription)")
            }
    }
}

extension PurchaseViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            pageControl.currentPage = 1
        } else {
            pageControl.currentPage = 0
        }
    }
}

final class PurchaseOptionsTableController: NSObject {
    
    private weak var tableView: UITableView!
    
    var dataSource = [SKProduct]()
    
    var didSelectRow: ((SKProduct, IndexPath) -> Void)?
    var updateHeight: (()->Void)?
    
    init(tableView: UITableView) {
        super.init()
        
        self.tableView = tableView
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(nibWithClass: PurchaseOptionTableViewCell.self)
    }
    
    func reloadData() {
        tableView.reloadData()
        let firstIndexPath = IndexPath(row: 0, section: 0)
        tableView.selectRow(at: firstIndexPath,
                            animated: false,
                            scrollPosition: .none)
        updateHeight?()
        
        guard let product = dataSource.first else {
            return
        }
        
        didSelectRow?(product, firstIndexPath)
    }
}

extension PurchaseOptionsTableController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueCell(withNibClass: PurchaseOptionTableViewCell.self,
                                     indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let product = dataSource[indexPath.row]
        
        guard let cell = cell as? PurchaseOptionTableViewCell else  { return }
        cell.priceLabel.text = product.localizedPrice
        cell.productTitleLabel.text = product.localizedTitle

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = dataSource[indexPath.row]
        didSelectRow?(product, indexPath)
    }
}
