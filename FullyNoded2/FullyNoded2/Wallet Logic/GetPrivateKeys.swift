//
//  GetPrivateKeys.swift
//  StandUp-Remote
//
//  Created by Peter on 20/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class GetPrivateKeys {
    
    var index = Int()
    var indexarray = [Int]()
    
    func getKeys(addresses: [String], completion: @escaping (([String]?)) -> Void) {
        
        func getAddressInfo(addresses: [String]) {
            
            var privkeyarray = [String]()
            
            if addresses.count > self.index {
                #warning("TODO: Continue refactoring")
                getActiveWalletNow { (wallet, error) in
                    
                    if !error && wallet != nil {
                        TorRPC.instance.executeRPCCommand(walletName: wallet!.name, method: .getaddressinfo, param: "\"\(addresses[self.index])\"") { [weak self] (result) in
                            switch result {
                            case .success(let response):
                                self?.index += 1
                                let responseDictionary = response as! NSDictionary
                                if let hdkeypath = responseDictionary["hdkeypath"] as? String {
                                    let arr = hdkeypath.components(separatedBy: "/")
                                    self?.indexarray.append(Int(arr[1])!)
                                    getAddressInfo(addresses: addresses)
                                } else {
                                    if let desc = responseDictionary["desc"] as? String {
                                        let arr = desc.components(separatedBy: "/")
                                        let index = (arr[1].components(separatedBy: "]"))[0]
                                        self?.indexarray.append(Int(index)!)
                                        getAddressInfo(addresses: addresses)
                                    }
                                }
                            case .failure(let error):
                                print("Error getting key path: \(error)")
                                completion(nil)
                            }
                        }
                    }
                }
            } else {
                
                print("loop finished")
                // loop is finished get the private keys
                let keyfetcher = KeyFetcher()
                
                for (i, keypathint) in indexarray.enumerated() {
                    
                    let int = Int(keypathint)
                    
                    keyfetcher.privKey(index: int) { (privKey, error) in
                        
                        if !error {
                            
                            privkeyarray.append(privKey!)
                            
                            if i == self.indexarray.count - 1 {
                                
                                completion(privkeyarray)
                                
                            }
                            
                        } else {
                            
                            print("error getting private key")
                            completion(nil)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        getAddressInfo(addresses: addresses)
        
    }
    
}
