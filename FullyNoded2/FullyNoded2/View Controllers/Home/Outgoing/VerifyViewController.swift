//
//  VerifyViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 03/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class VerifyViewController: UIViewController {

    var address = ""
    let connectingView = ConnectingView()
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("address = \(address)")
        connectingView.addConnectingView(vc: self, description: "getting address info")
        getAddressInfo(address: address)
        
    }
    
    #warning("TODO: Continue refactoring")
    func getAddressInfo(address: String) {
        let param = "\"\(address)\""
        
        getActiveWalletNow { (wallet, error) in
            if wallet != nil && !error {
                TorRPC.instance.executeRPCCommand(walletName: wallet!.name, method: .getaddressinfo, param: param) { [weak self] (result) in
                    switch result {
                    case .success(let response):
                        let responseDictionary = response as! NSDictionary
                        DispatchQueue.main.async {
                            self?.connectingView.removeConnectingView()
                            self?.textView.text = "\(responseDictionary)"
                        }
                    case .failure(let error):
                        self?.connectingView.removeConnectingView()
                        displayAlert(viewController: self!, isError: true, message: "\(error)")
                    }
                }
            }
        }
    }
}
