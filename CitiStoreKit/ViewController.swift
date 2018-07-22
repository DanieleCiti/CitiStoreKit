//
//  ViewController.swift
//  CitiStoreKit
//
//  Created by Daniele Citi on 22/07/18.
//  Copyright © 2018 Daniele Citi. All rights reserved.
//

import UIKit

// In order to make the CSKService class works, remember to install the SwiftyStoreKit framework via CocoaPod into your project.

class ViewController: UIViewController {
    
    // 1) Decleare a variable of type CSKService
    var inAppService: CSKService!

    override func viewDidLoad() {
        super.viewDidLoad()
  
        // 2) Set the delegate and the shared secret properties.
        inAppService.delegate = self
        inAppService.sharedSecret = "Your shared Secret. You can get in on iTunes Connect"
    }
    
    // 3) Just call the functions you need.
    func exampleFuncPurchase()
    {
        inAppService.purchaseProduct(with: "InAppID", type: .simple, successSegueID: "yourID", errorSegueID: "yourID")
    }
    
    func exampleVerifyPurchase()
    {
        inAppService.verifyPurchase(with: "inAppID", type: .autoRenewable, segueIDPurchased: "yourID", segueIDFailed: "YourID")
    }
    
    func exampleRestorePurchase()
    {
        inAppService.restorePurchase(segueIDFailed: "yourID", segueIDSuccess: "yourID", segueIDNothingToRestore: "yourID")
    }

    // Finish. Easy, isn't it? :)
    
}



