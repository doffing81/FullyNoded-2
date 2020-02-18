//
//  TransactionViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class TransactionViewController: UIViewController {
    
    var txid = ""
    let creatingView = ConnectingView()
    
    @IBOutlet var textView: UITextView!
    
    @IBAction func back(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        creatingView.addConnectingView(vc: self,
                                       description: "getting transaction")
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        executeNodeCommand(method: BTC_CLI_COMMAND.gettransaction,
                              param: "\"\(txid)\", true")
        
    }

    #warning("TODO: Continue refactoring")
    // TODO: Rename for specific command
    func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
        
        getActiveWalletNow { (wallet, error) in
            if wallet != nil && !error {
                TorRPC.instance.executeRPCCommand(walletName: wallet!.name, method: method, param: param) { [weak self] (result) in
                    switch result {
                    case .success(let response):
                        switch method {
                        case BTC_CLI_COMMAND.gettransaction:
                            let responseDictionary = response as! NSDictionary
                            DispatchQueue.main.async {
                                self?.textView.text = "\(responseDictionary)"
                                self?.creatingView.removeConnectingView()
                            }
                        default:
                            break
                        }
                    case .failure(let error):
                        self?.creatingView.removeConnectingView()
                        
                        displayAlert(viewController: self!, isError: true, message: "\(error)")
                    }
                }
            }
        }
    }
}
