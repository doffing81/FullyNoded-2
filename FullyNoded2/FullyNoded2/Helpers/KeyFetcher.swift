//
//  KeyFetcher.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation
import LibWally

class KeyFetcher {
    
    let enc = Encryption()
    
    func privKey(index: Int, completion: @escaping ((privKey: String?, error: Bool)) -> Void) {
        
        getActiveWalletNow() { (wallet, error) in
            
            if wallet != nil && !error {
                
                let derivationPath = wallet!.derivation
                
                let enc = Encryption()
                enc.decryptData(dataToDecrypt: wallet!.seed) { (seed) in
                    
                    if seed != nil {
                        
                        let words = String(data: seed!, encoding: .utf8)!
                        
                        let mnenomicCreator = MnemonicCreator()
                        
                        mnenomicCreator.convert(words: words) { (mnemonic, error) in
                            
                            if !error {
                                
                                if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivationPath)) {
                                    
                                    if let path = BIP32Path(derivationPath) {
                                        
                                        do {
                                            
                                            let account = try masterKey.derive(path)
                                            
                                            if let childPath = BIP32Path("\(index)") {
                                                
                                                do {
                                                    
                                                    let key = try account.derive(childPath)
                                                    
                                                    if let keyToReturn = key.privKey {
                                                        
                                                        let wif = keyToReturn.wif
                                                        completion((wif,false))
                                                        
                                                    } else {
                                                        
                                                        completion((nil,true))
                                                        
                                                    }
                                                    
                                                } catch {
                                                    
                                                    completion((nil,true))
                                                    
                                                }
                                                
                                            }
                                            
                                        } catch {
                                            
                                            completion((nil,true))
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((nil,true))
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((nil,true))
                                    
                                }
                                
                            } else {
                                
                                completion((nil,true))
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func key(index: Int, completion: @escaping ((key: HDKey?, error: Bool)) -> Void) {
        
        getActiveWalletNow() { (wallet, error) in
            
            if wallet != nil && !error {
                
                let derivationPath = wallet!.derivation
                
                let enc = Encryption()
                enc.decryptData(dataToDecrypt: wallet!.seed) { (seed) in
                    
                    if seed != nil {
                        
                        let words = String(data: seed!, encoding: .utf8)!
                        let mnenomicCreator = MnemonicCreator()
                        mnenomicCreator.convert(words: words) { (mnemonic, error) in
                            
                            if !error {
                                
                                if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivationPath)) {
                                    
                                    if let path = BIP32Path(derivationPath) {
                                        
                                        do {
                                            
                                            let account = try masterKey.derive(path)
                                            
                                            if let childPath = BIP32Path("\(index)") {
                                                
                                                do {
                                                    
                                                    let key = try account.derive(childPath)
                                                    completion((key,false))
                                                    
                                                } catch {
                                                    
                                                    completion((nil,true))
                                                    
                                                }
                                                
                                            }
                                            
                                        } catch {
                                            
                                            completion((nil,true))
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((nil,true))
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((nil,true))
                                    
                                }
                                
                            } else {
                                
                                completion((nil,true))
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func bip32Xpub(wallet: WalletStruct, completion: @escaping ((xpub: String?, error: Bool)) -> Void) {
        
        let derivationPath = wallet.derivation
        
        let enc = Encryption()
        enc.decryptData(dataToDecrypt: wallet.seed) { (seed) in
            
            if seed != nil {
                
                let words = String(data: seed!, encoding: .utf8)!
                let mnenomicCreator = MnemonicCreator()
                mnenomicCreator.convert(words: words) { (mnemonic, error) in
                    
                    if !error {
                        
                        if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivationPath)) {
                            
                            if let path = BIP32Path(derivationPath) {
                                
                                do {
                                    
                                    let account = try masterKey.derive(path)
                                    completion((account.xpub,false))
                                    
                                } catch {
                                    
                                    completion((nil,true))
                                    
                                }
                                
                            } else {
                                
                                completion((nil,true))
                                
                            }
                            
                        } else {
                            
                            completion((nil,true))
                            
                        }
                        
                    } else {
                        
                        completion((nil,true))
                        
                    }
                    
                }
                
            } else {
                
                completion((nil,true))
                
            }
            
        }
        
    }
    
    func bip32Xprv(completion: @escaping ((xprv: String?, error: Bool)) -> Void) {
        
        getActiveWalletNow() { (wallet, error) in
            
            if wallet != nil && !error {
                
                let derivationPath = wallet!.derivation
                let enc = Encryption()
                enc.decryptData(dataToDecrypt: wallet!.seed) { (seed) in
                    
                    if seed != nil {
                        
                        let words = String(data: seed!, encoding: .utf8)!
                        let mnenomicCreator = MnemonicCreator()
                        mnenomicCreator.convert(words: words) { (mnemonic, error) in
                            
                            if !error {
                                
                                if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivationPath)) {
                                    
                                    if let path = BIP32Path(derivationPath) {
                                        
                                        do {
                                            
                                            let account = try masterKey.derive(path)
                                            
                                            if let xprv = account.xpriv {
                                                
                                                completion((xprv,false))
                                                
                                            } else {
                                                
                                                completion((nil,true))
                                                
                                            }
                                            
                                        } catch {
                                            
                                            completion((nil,true))
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((nil,true))
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((nil,true))
                                    
                                }
                                
                            } else {
                                
                                completion((nil,true))
                                
                            }
                            
                        }
                        
                    } else {
                        
                        completion((nil,true))
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func musigAddress(completion: @escaping ((address: String?, error: Bool)) -> Void) {
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil && !error {
                
                let index = wallet!.index + 1
                let param = "\"\(wallet!.descriptor)\", [\(index),\(index)]"
                
                TorRPC.instance.executeRPCCommand(walletName: wallet!.name, method: .deriveaddresses, param: param) { [weak self] (result) in
                    switch result {
                    case .success(let response):
                        self?.updateIndex(wallet: wallet!)
                        let responseArray = response as! NSArray
                        let address = responseArray[0] as! String
                        completion((address,false))
                    case .failure(let error):
                        print("Error deriving addresses: \(error)")
                        completion((nil,true))
                    }
                }
            }
        }
    }
    #warning("TODO: Continue refactoring")
    func musigChangeAddress(completion: @escaping ((address: String?, error: Bool)) -> Void) {
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil && !error {
                let index = wallet!.index + 1000
                
                if wallet!.index < 1000 {
                    let param = "\"\(wallet!.descriptor)\", [\(index),\(index)]"
                    
                    TorRPC.instance.executeRPCCommand(walletName: wallet!.name, method: .deriveaddresses, param: param) { (result) in
                        switch result {
                        case .success(let response):
                            let responseArray = response as! NSArray
                            let address = responseArray[0] as! String
                            completion((address,false))
                        case .failure(let error):
                            print("Error deriving addresses: \(error)")
                            completion((nil,true))
                        }
                    }
                } else {
                    // FIXME: Should execute completion?
                    print("Error, need to import more keys")
                }
            }
        }
    }
    
    private func updateIndex(wallet: WalletStruct) {
        
        let cd = CoreDataService()
        cd.updateEntity(id: wallet.id, keyToUpdate: "index", newValue: wallet.index + 1, entityName: .wallets) {
            
            if !cd.errorBool {
                
                
            } else {
                
                print("error updating index: \(cd.errorDescription)")
                
            }
            
        }
        
    }
    
}
