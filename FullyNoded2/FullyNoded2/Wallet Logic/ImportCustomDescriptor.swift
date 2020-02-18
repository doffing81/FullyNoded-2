//
//  ImportCustomDescriptor.swift
//  FullyNoded2
//
//  Created by Peter on 10/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class ImportColdMultiSigDescriptor {
    
    #warning("TODO: Continue refactoring")
    func create(descriptor: String, completion: @escaping ((success: Bool, error:Bool, errorDescription: String?)) -> Void) {
        
        let enc = Encryption()
        enc.getNode { (node, error) in
            
            if node != nil && !error {
                
                var newWallet = [String:Any]()
                newWallet["birthdate"] = keyBirthday()
                newWallet["id"] = UUID()
                newWallet["isActive"] = false
                newWallet["name"] = "\(randomString(length: 10))_StandUp"
                newWallet["lastUsed"] = Date()
                newWallet["lastBalance"] = 0.0
                newWallet["type"] = "CUSTOM"
                newWallet["nodeId"] = node!.id
                newWallet["isArchived"] = false
                let str = WalletStruct(dictionary: newWallet)
                
                let param = "\"\(str.name)\", true, true, \"\", true"
                TorRPC.instance.executeRPCCommand(walletName: str.name, method: .createwallet, param: param) { (result) in
                    switch result {
                    case .success:
                        TorRPC.instance.executeRPCCommand(walletName: "", method: .getdescriptorinfo, param: "\"\(descriptor)\"") { (result) in
                            switch result {
                            case .success(let response):
                                let responseDictionary = response as! NSDictionary
                                let processedDescriptor = responseDictionary["descriptor"] as! String
                                
                                newWallet["descriptor"] = processedDescriptor
                                
                                var params = ""
                                let descParser = DescriptorParser()
                                let descStruct = descParser.descriptor(processedDescriptor)
                                
                                if descStruct.isHot {
                                    if !descStruct.isMulti {
                                        params = "[{ \"desc\": \"\(processedDescriptor)\", \"timestamp\": \"now\", \"range\": [0,1999], \"watchonly\": false, \"label\": \"FullyNoded2\", \"keypool\": true, \"internal\": false }]"
                                    } else {
                                        params = "[{ \"desc\": \"\(processedDescriptor)\", \"timestamp\": \"now\", \"range\": [0,1999], \"watchonly\": false, \"label\": \"FullyNoded2\", \"keypool\": false, \"internal\": false }]"
                                    }
                                } else {
                                    if !descStruct.isMulti {
                                        params = "[{ \"desc\": \"\(processedDescriptor)\", \"timestamp\": \"now\", \"range\": [0,1999], \"watchonly\": true, \"label\": \"FullyNoded2\", \"keypool\": false, \"internal\": false }]"
                                        
                                    } else {
                                        params = "[{ \"desc\": \"\(processedDescriptor)\", \"timestamp\": \"now\", \"range\": [0,1999], \"watchonly\": true, \"label\": \"FullyNoded2\", \"keypool\": true, \"internal\": false }]"
                                    }
                                }
                                TorRPC.instance.executeRPCCommand(walletName: str.name, method: .importmulti, param: params) { (result) in
                                    switch result {
                                    case .success:
                                        let walletSaver = WalletSaver()
                                        walletSaver.save(walletToSave: newWallet) { (success) in
                                            if success {
                                                completion((true, false, nil))
                                            } else {
                                                completion((false, true, "Failed saving wallet locally"))
                                            }
                                        }
                                    case .failure(let error):
                                        completion((false, true, "\(error)"))
                                    }
                                }
                            case .failure(let error):
                                completion((false, true, "\(error)"))
                            }
                        }
                    case .failure(let error):
                        completion((false, true, "\(error)"))
                    }
                }
            } else {
                completion((false, true, "error getting active node"))
            }
        }
    }
}
