//
//  CreateMultisigWallet.swift
//  StandUp-Remote
//
//  Created by Peter on 14/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class CreateMultiSigWallet {
    
    let cd = CoreDataService()
    let enc = Encryption()
    
    #warning("TODO: Continue refactoring")
    func create(wallet: WalletStruct, nodeXprv: String, nodeXpub: String, completion: @escaping ((Bool)) -> Void) {
                
        func importMulti(param: Any) {
        
            TorRPC.instance.executeRPCCommand(walletName: wallet.name, method: .importmulti, param: param) { (result) in
                switch result {
                case .success(let response):
                    let responseArray = response as! NSArray
                    let success = (responseArray[0] as! NSDictionary)["success"] as! Bool
                    
                    if success {
                        print("success")
                        completion(true)
                    } else {
                        let errorDict = (responseArray[0] as! NSDictionary)["error"] as! NSDictionary
                        let error = errorDict["message"] as! String
                        print("Error importing multi: \(error)")
                        completion(false)
                    }
                case .failure(let error):
                    print("Error importmulti: \(error)")
                    completion(false)
                }
            }
        }
        
        func createWallet() {
                
            let param = "\"\(wallet.name)\", false, true, \"\", true"
            
            TorRPC.instance.executeRPCCommand(walletName: wallet.name, method: .createwallet, param: param) { (result) in
                switch result {
                case .success:
                    let descriptorArray = (wallet.descriptor).split(separator: "#")
                    var descriptor = "\(descriptorArray[0])"
                    descriptor = descriptor.replacingOccurrences(of: nodeXpub, with: nodeXprv)
                    
                    TorRPC.instance.executeRPCCommand(walletName: wallet.name, method: .getdescriptorinfo, param: "\"\(descriptor)\"") { (result) in
                        switch result {
                        case .success(let response):
                            let responseDictionary = response as! NSDictionary
                            let updatedDescriptor = responseDictionary["descriptor"] as! String
                            let checksum = responseDictionary["checksum"] as! String
                            let array = updatedDescriptor.split(separator: "#")
                            let hotDescriptor = "\(array[0])" + "#" + checksum
                            var params = "[{ \"desc\": \"\(hotDescriptor)\", \"timestamp\": \"now\", \"range\": [0,1999], \"watchonly\": false, \"label\": \"StandUp\", \"keypool\": false, \"internal\": false }]"
                            params = params.replacingOccurrences(of: nodeXpub, with: nodeXprv)
                            importMulti(param: params)
                        
                        // TODO: Failure case did not previously exist. Check if necessary or warranted.
                        case .failure:
                            print("Error creating wallet")
                            completion(false)
                        }
                    }
                case .failure:
                    print("Error creating wallet")
                    completion(false)
                }
            }
        }
        
        createWallet()
    }
}
