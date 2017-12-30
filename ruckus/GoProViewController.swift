//
//  GoProViewController.swift
//  ruckus
//
//  Created by Gareth on 04.06.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit
import StoreKit
import SwiftyStoreKit

enum ValidationChecks: String {
    case bundleId = "garethfuller.ruckus.lite"
    case productId = "ruckus_pro_version"
    case secret = "76d710a6a8b14059813c9e4318474257"
}

class GoProViewController: UIViewController {
    
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var restorePurchaseButton: UIButton!
    
    var loadedProduct: SKProduct?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if currentReachabilityStatus == .notReachable {
            blockingPaymentError(withMessage: "No Internet connection, unable to make purchase")
        } else {
        
            // start loading the request for the go pro product
            if SKPaymentQueue.canMakePayments() {
                getProductInfo()
            } else {
                blockingPaymentError(withMessage: "In app purchases disabled, please enable in settings")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationItem.title = "Go Pro!"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func getProductInfo() {
        if PurchasedState.sharedInstance.isPaid {
            return
        }
        
        SwiftyStoreKit.retrieveProductsInfo([ValidationChecks.productId.rawValue]) { result in
            
            guard let product = result.retrievedProducts.first else {
                self.blockingPaymentError(withMessage: "Unable to fetch product, please check internet connection")
                return
            }
            
            if let formattedPrice = self.getFormattedPrice(forProduct: product) {
                self.buyButton.setTitle("Buy now: \(formattedPrice)", for: .normal)
                self.loadedProduct = product
            } else {
                self.blockingPaymentError(withMessage: "Unable to fetch product, please check internet connection")
            }
        }
    }
    
    func getFormattedPrice(forProduct product: SKProduct) -> String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.formatterBehavior = .behavior10_4
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = product.priceLocale
        
        return numberFormatter.string(from: product.price)
    }
    
    func blockingPaymentError(withMessage message: String) {
        disableButtons()
        buyButton.setTitle("Error", for: .normal)
        errorMessage.text = message
        errorMessage.isHidden = false
    }
    
    // MARK: - Payment life cycle events
    func paymentSuccess() {
        // show success and thanks
        activityIndicator.isHidden = true
        disableButtons()
        buyButton.setTitle("Purchased!", for: .normal)
        UserDefaults.standard.set(true, forKey: "proVersion")
        PurchasedState.sharedInstance.isPaid = true
    }
    
    
    // After a payment we check that the reciept is valid
    func validateReceipt() {
        let appleValidator = AppleReceiptValidator(service: .production)
        SwiftyStoreKit.verifyReceipt(using: appleValidator, password: ValidationChecks.secret.rawValue) { result in
            switch result {
            case .success(let receipt):
                // Verify the purchase of Consumable or NonConsumable
                let purchaseResult = SwiftyStoreKit.verifyPurchase(
                    productId: ValidationChecks.productId.rawValue,
                    inReceipt: receipt)
                
                switch purchaseResult {
                case .purchased(_):
                    self.paymentSuccess()
                case .notPurchased:
                    self.paymentFailed()
                    self.updateError(withMessage: "Unable the validate the reciept from the apple store")
                }
            case .error(_):
                self.paymentFailed()
                self.updateError(withMessage: "Unable the validate the reciept from the apple store")
            }
        }

    }
    
    func updateError(withMessage message: String) {
        errorMessage.text = message
        errorMessage.isHidden = false
    }
    
    
    func paymentFailed() {
        resetUI()
        
        // if there was no error just a cancel
        if let formattedPrice = getFormattedPrice(forProduct: loadedProduct!) {
            buyButton.setTitle("Buy now: \(formattedPrice)", for: .normal)
        }
    }
    
    
    func startPayment() {
        // show animation
        activityIndicator.isHidden = false
        buyButton.setTitle("Purchasing", for: .normal)
    }
    
    func resetUI() {
        activityIndicator.isHidden = true
        restorePurchaseButton.isEnabled = true
        buyButton.isEnabled = true
    }
    
    func disableButtons() {
        restorePurchaseButton.isEnabled = false
        buyButton.isEnabled = false
    }
    
    // MARK: - IB Actions
    @IBAction func tapBuy(_ sender: Any) {
        // if the product is not there, just bail out of here
        guard let _ = loadedProduct else {
            return
        }
        disableButtons()
        errorMessage.isHidden = true
        
        startPayment()
        
        // make the purchase!
        SwiftyStoreKit.purchaseProduct(ValidationChecks.productId.rawValue, quantity: 1, atomically: true) { result in
            
            switch result {
            case .success(_):
                self.validateReceipt()
            case .error(_):
                self.paymentFailed()
                //@TODO this needs the be handled when swifty store kit is updated
                self.updateError(withMessage: "Unbale to make purchase")
//                switch error.code {
//                case .unknown:
//                    self.paymentFailed()
//                    self.updateError(withMessage: "Unknown error.")
//                case .clientInvalid:
//                    self.paymentFailed()
//                    self.updateError(withMessage: "Not allowed to make the payment")
//                case .paymentCancelled:
//                    self.paymentFailed()
//                case .paymentInvalid:
//                    self.paymentFailed()
//                    self.updateError(withMessage: "The purchase identifier was invalid.")
//                case .paymentNotAllowed:
//                    self.paymentFailed()
//                    self.updateError(withMessage: "The device is not allowed to make the payment.")
//                case .storeProductNotAvailable:
//                    self.paymentFailed()
//                    self.updateError(withMessage: "The product is not available in the current storefront.")
//                case .cloudServicePermissionDenied:
//                    self.paymentFailed()
//                    self.updateError(withMessage: "Access to cloud service information is not allowed.")
//                case .cloudServiceNetworkConnectionFailed:
//                    self.paymentFailed()
//                    self.updateError(withMessage: "Could not connect to the network.")
//                case .cloudServiceRevoked:
//                    self.paymentFailed()
//                    self.updateError(withMessage: "User has revoked permission to use this cloud service")
//                }
            }
        }
        
    }
    
    // user wishes to restore a purchase
    @IBAction func tapRestorePurchase(_ sender: Any) {
        disableButtons()
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            if results.restoreFailedPurchases.count > 0 {
                self.resetUI()
                self.updateError(withMessage: "Unable to restore, please try again")
            }
            else if results.restoredPurchases.count > 0 {
                self.paymentSuccess()
            }
            else {
                self.updateError(withMessage: "Nothing to restore")
                self.resetUI()
            }
        }
    }


}
