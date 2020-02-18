//
//  WalletInfoViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 14/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletInfoViewController: UIViewController {

    var walletname = ""
    let connectingView = ConnectingView()
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectingView.addConnectingView(vc: self, description: "getting wallet info")
        getWalletInfo()
        
    }
    
    #warning("TODO: Continue refactoring")
    func getWalletInfo() {
        
        getActiveWalletNow { (wallet, error) in
            if !error && wallet != nil {
                TorRPC.instance.executeRPCCommand(walletName: wallet!.name, method: .getwalletinfo, param: "") { [weak self] (result) in
                    switch result {
                    case .success(let response):
                        DispatchQueue.main.async {
                            let responseDictionary = response as! NSDictionary
                            self?.textView.text = "\(responseDictionary)"
                            self?.connectingView.removeConnectingView()
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
