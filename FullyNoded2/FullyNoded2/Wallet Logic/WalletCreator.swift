//
//  WalletCreator.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class WalletCreator {
    
    var importingChange = false
    var descriptor = ""
    var errorString = ""
    var statusDescription = "Creating your wallet..."
    var progress = Int()
    var walletDict = [String:Any]()
    var node:NodeStruct!
    
    func createStandUpWallet(derivation: String, completion: @escaping ((success: Bool, errorDescription: String?, descriptor: String?)) -> Void) {
        
        let wallet = WalletStruct.init(dictionary: walletDict)
        
        //getActiveWallet { (wallet) in
        
        //            func whichChain() {
        //
        //                self.statusDescription = "Checking which network your node is on..."
        //                self.progress = 10
        //
        //                executeNodeCommand(method: .getblockchaininfo,
        //                                   param: "")
        //
        //            }
        
        func createStandUpWallet() {
            
            self.statusDescription = "Creating the wallet on your node..."
            self.progress = 40
            // create it
            let param = "\"\(wallet.name)\", true, true, \"\", true"
            executeNodeCommand(method: .createwallet, param: param)
            
        }
        
        #warning("TODO: Continue refactoring")
        func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
            TorRPC.instance.executeRPCCommand(walletName: wallet.name, method: method, param: param) { [weak self] (result) in
                switch result {
                case .success(let response):
                    switch method {
                    case .createwallet:
                        let responseDictionary = response as! NSDictionary
                        handleWalletCreation(response: responseDictionary)
                    case .importmulti:
                        let responseArray = response as! NSArray
                        let success = (responseArray[0] as! NSDictionary)["success"] as! Bool
                        
                        if success {
                            if self!.importingChange {
                                self?.progress = 100
                                completion((true, nil, self!.descriptor))
                            } else {
                                importChangeKeys()
                            }
                        } else {
                            let errorDict = (responseArray[0] as! NSDictionary)["error"] as! NSDictionary
                            let error = errorDict["message"] as! String
                            completion((false, error, nil))
                        }
                        if let warnings = (responseArray[0] as! NSDictionary)["warnings"] as? NSArray {
                            if warnings.count > 0 {
                                for warning in warnings {
                                    let warn = warning as! String
                                    self?.errorString += warn
                                }
                            }
                        }
                    case .getdescriptorinfo:
                        self?.progress = 60
                        let responseDictionary = response as! NSDictionary
                        self?.descriptor = "\"\(responseDictionary["descriptor"] as! String)\""
                        let params = "[{ \"desc\": \(self!.descriptor), \"timestamp\": \"now\", \"range\": [0,999], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": true, \"internal\": false }]"
                        
                        executeNodeCommand(method: .importmulti, param: params)
                    default:
                        break
                    }
                case .failure(let error):
                    completion((false, "\(error)", nil))
                }
            }
        }
        
        func handleWalletCreation(response: NSDictionary) {
            
            let warning = response["warning"] as! String
            
            if warning == "" {
                
                
            } else {
                
                // should return an error to alert user to anything that may have gone wrong
                print("warning from bitcoin core: \(warning)")
                
            }
            
            importPrimaryAddresses()
            
        }
        
        func importPrimaryAddresses() {
            print("importPrimaryAddresses")
            
            self.statusDescription = "Importing 1,000 addresses into your nodes wallet..."
            self.progress = 50
            
            //get the xpub
            let keyFetcher = KeyFetcher()
            keyFetcher.bip32Xpub(wallet: wallet) { (xpub, error) in
                
                if !error {
                    
                    var param = ""
                    
                    switch wallet.derivation {
                        
                    case "m/84'/1'/0'/0", "m/84'/0'/0'/0":
                        
                        param = "\"wpkh(\(xpub!)/*)\""
                        
                    case "m/44'/1'/0'/0", "m/44'/0'/0'/0":
                        
                        param = "\"pkh(\(xpub!)/*)\""
                        
                    case "m/49'/1'/0'/0", "m/49'/0'/0'/0":
                        
                        param = "\"sh(wpkh(\(xpub!)/*))\""
                        
                    default:
                        
                        break
                        
                    }
                    
                    executeNodeCommand(method: .getdescriptorinfo, param: param)
                    
                } else {
                    
                    print("error getting xpub")
                    
                }
                
            }
            
        }
        
        func importChangeKeys() {
            
            self.statusDescription = "Importing 1,000 change addresses into your nodes wallet..."
            self.importingChange = true
            let params = "[{ \"desc\": \(self.descriptor), \"timestamp\": \"now\", \"range\": [1000,1999], \"watchonly\": true, \"keypool\": true, \"internal\": true }]"
            executeNodeCommand(method: .importmulti, param: params)
            
        }
        
        
        self.progress = 0
        createStandUpWallet()
        
    }
    
}
