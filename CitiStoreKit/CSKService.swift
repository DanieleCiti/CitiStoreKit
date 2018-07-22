//
//  CSTService.swift
//  CitiStoreKit
//
//  Created by Daniele Citi on 20/07/18.
//  Copyright © 2018 Daniele Citi. All rights reserved.
//

import SwiftyStoreKit

/// Class that manages all the In-App Purchase logic. This class offers a set of methods you can implement to buy, verify or restore an In-app purchase.
class CSKService {
    // MARK: Properties
    
    /// The ViewController that manages the transiction by performing a segue.
    var delegate: UIViewController
    /// Your In-App purchases Shared Secred generated on iTunes Connect.
    var sharedSecret: String
    
    // Finish properties
    
    required init(_ del: UIViewController, _ sharedSec: String) {
        
        delegate = del
        sharedSecret = sharedSec
        
    }

    // MARK: Methods
    
    /// Purchase a product.
    /// - parameter id: The ID associated with the In-App purchase. See that in Itunes Connect.
    /// - parameter type: The type of the purchase choosen from the enum PurchaseType.
    /// - parameter validDuration: Check if a subscription is still valid or expired.
    /// - parameter successSegueID: The ID of a segue that you want to perform after the product has been purchased.
    /// - parameter errorSegueID: The ID of a segue that you want to perform if the transiction is failed.
    func purchaseProduct(with id: String, type: PurchaseType, validDuration: TimeInterval? = nil, successSegueID: String, errorSegueID: String)
    {
        if type == .simple
        {
            SwiftyStoreKit.retrieveProductsInfo([id]) { result in
                if let product = result.retrievedProducts.first {
                    SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { result in
                        // handle result (same as above)
                        switch result {
                        case .success(let product):
                            // fetch content from your server, then:
                            if product.needsFinishTransaction {
                                SwiftyStoreKit.finishTransaction(product.transaction)
                            }
                            print("Purchase Success: \(product.productId)")
                            self.delegate.performSegue(withIdentifier: successSegueID, sender: self.delegate)
                            
                        case .error(let error):
                            switch error.code { // finire
                            case .unknown:
                                self.alertPurchaseError(title: "Unknown error.", message: "Please contact support", segueID: errorSegueID)
                            case .clientInvalid:
                                self.alertPurchaseError(title: "Error.", message: "Not allowed to make the payment", segueID: errorSegueID)
                            case .paymentCancelled:
                                break
                            case .paymentInvalid:
                                self.alertPurchaseError(title: "Error.", message: "The purchase identifier was invalid", segueID: errorSegueID)
                            case .paymentNotAllowed:
                                self.alertPurchaseError(title: "Error.", message: "The device is not allowed to make the payment", segueID: errorSegueID)
                            case .storeProductNotAvailable:
                                self.alertPurchaseError(title: "Error.", message: "The product is not available in the current storefront", segueID: errorSegueID)
                            case .cloudServicePermissionDenied:
                                self.alertPurchaseError(title: "Error.", message: "Access to cloud service information is not allowed", segueID: errorSegueID)
                            case .cloudServiceNetworkConnectionFailed:
                                self.alertPurchaseError(title: "Error.", message: "Could not connect to the network", segueID: errorSegueID)
                            case .cloudServiceRevoked:
                                self.alertPurchaseError(title: "Error.", message: "User has revoked permission to use this cloud service", segueID: errorSegueID)
                            }
                        }
                    }
                }
            }
        } else // abbonamento
        {
            SwiftyStoreKit.purchaseProduct(id, atomically: true) { result in
                
                if case .success(let purchase) = result {
                    // Deliver content from server, then:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    self.delegate.performSegue(withIdentifier: successSegueID, sender: self.delegate)
                
                } else {
                    // purchase error
                    self.alertPurchaseError(title: "Error", message: "Unable to purchase this product.", segueID: errorSegueID)
                }
            }
        }
        
    } // fine func
    
    /// Check if the user has purchased a product.
    /// - parameter id: The ID associated with the In-App purchase. See that in Itunes Connect.
    /// - parameter type: The type of the purchase choosen from the enum PurchaseType.
    /// - parameter validDuration: Check if a subscription is still valid or expired.
    /// - parameter segueIDPurchased: The ID of a segue that you want to perform if the user has already purchaed the product.
    /// - parameter segueIDFailed: The ID of a segue that you want to perform if the user has never purchased the product.
    func verifyPurchase(with id: String, type: PurchaseType, validDuration: TimeInterval? = nil, segueIDPurchased: String?, segueIDFailed: String?)
    {
        // NON FUNZIONA SU SIMULATORE, SOLO DEVICE REALE con accesso eseguito come SandBoxTester
        
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                
                // Verify the purchase of a Subscription
                switch type {
                case .simple:
                    let purchaseResult = SwiftyStoreKit.verifyPurchase(
                        productId: id,
                        inReceipt: receipt)
                    
                    switch purchaseResult {
                    case .purchased(let receiptItem):
                        print("product is purchased \(receiptItem)")
                        self.delegate.performSegue(withIdentifier: segueIDPurchased!, sender: self.delegate)
                    case .notPurchased:
                        print("The user has never purchased \(id)")
                        self.delegate.performSegue(withIdentifier: segueIDFailed!, sender: self.delegate)
                    }
                case .autoRenewable:
                    let purchaseResult = SwiftyStoreKit.verifySubscription(
                        ofType: .autoRenewable, // or .nonRenewing (see below)
                        productId: id,
                        inReceipt: receipt)
                    
                    switch purchaseResult {
                    case .purchased(let expiryDate, let items):
                        print("\(id) is valid until \(expiryDate)\n\(items)\n")
                        self.delegate.performSegue(withIdentifier: segueIDPurchased!, sender: self.delegate)
                    case .expired(let expiryDate, let items):
                        print("\(id) is expired since \(expiryDate)\n\(items)\n")
                        self.delegate.performSegue(withIdentifier: segueIDFailed!, sender: self.delegate)
                    case .notPurchased:
                        print("The user has never purchased \(id)")
                        self.delegate.performSegue(withIdentifier: segueIDFailed!, sender: self.delegate)
                    }
                case .nonRenewing:
                    guard let validDuration = validDuration else {return}
                    // validDuration: time interval in seconds
                    let purchaseResult = SwiftyStoreKit.verifySubscription(
                        ofType: .nonRenewing(validDuration: validDuration),
                        productId: id,
                        inReceipt: receipt)
                    
                    switch purchaseResult {
                    case .purchased(let expiryDate, let items):
                        print("\(id) is valid until \(expiryDate)\n\(items)\n")
                        self.delegate.performSegue(withIdentifier: segueIDPurchased!, sender: self.delegate)
                    case .expired(let expiryDate, let items):
                        print("\(id) is expired since \(expiryDate)\n\(items)\n")
                        self.delegate.performSegue(withIdentifier: segueIDFailed!, sender: self.delegate)
                    case .notPurchased:
                        print("The user has never purchased \(id)")
                        self.delegate.performSegue(withIdentifier: segueIDFailed!, sender: self.delegate)
                    }
                    
                }
                
            case .error(let error):
                print("Receipt verification failed: \(error)")
            }
        }
    }
    
    
    /// Mandatory by Apple policy: Call this method to allow to the user to restore a purchase.
    /// - parameter segueIDFailed: The ID of a segue that you want to perform if the operation is failed.
    /// - parameter segueIDSuccess: The ID of a segue that you want to perform if the operation is succeded.
    /// - parameter segueIDSuccess: The ID of a segue that you want to perform if there is nothing to restore.
    func restorePurchase(segueIDFailed: String, segueIDSuccess: String, segueIDNothingToRestore: String)
    {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            if results.restoreFailedPurchases.count > 0 {
                print("Restore Failed: \(results.restoreFailedPurchases)")
                self.createAlert(title: "Operazione fallita", message: "Errore nel ripristino dell'acquisto", segue: segueIDFailed)
            }
            else if results.restoredPurchases.count > 0 {
                print("Restore Success: \(results.restoredPurchases)")
                self.createAlert(title: "Acquisto ripristinato", message: "Acquisto ripristinato con successo!", segue: segueIDSuccess)
            }
            else {
                print("Nothing to Restore")
                self.createAlert(title: "Nessun acquisto da ripristinare", message: "Niente da ripristinare", segue: segueIDNothingToRestore)
            }
        }
    }
    
 private func createAlert(title: String, message: String, segue: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        // CREA UN BOTTONE - solo uno per tipo.
        alert.addAction(UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            self.delegate.performSegue(withIdentifier: segue, sender: self)
        }))
        
            delegate.present(alert, animated: true, completion: nil)
    }
    
    private func alertPurchaseError(title: String, message: String, segueID: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        // CREA UN BOTTONE - solo uno per tipo.
        alert.addAction(UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            self.delegate.performSegue(withIdentifier: segueID, sender: self.delegate)
        }))
        
        self.delegate.present(alert, animated: true, completion: nil)
    }
    
    enum PurchaseType: Int
    {
        case simple = 0,
        autoRenewable,
        nonRenewing
    }

} // fine classe
