//
//  NodeLogic.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class NodeLogic {
    
    let dateFormatter = DateFormatter()
    var errorBool = Bool()
    var errorDescription = ""
    var dictToReturn = [String:Any]()
    var arrayToReturn = [[String:Any]]()
    var walletsToReturn = NSArray()
    var walletDisabled = Bool()
    var wallet:WalletStruct!
    
    #warning("TODO: Continue refactoring all methods, if not the whole file.")
    func loadSectionOne(completion: @escaping () -> Void) {
        TorRPC.instance.executeRPCCommand(walletName: "", method: .getnetworkinfo, param: "") { [weak self] (result) in
            switch result {
            case .success(let response):
                let responseDictionary = response as! NSDictionary
                let subversion = (responseDictionary["subversion"] as! String).replacingOccurrences(of: "/", with: "")
                self?.dictToReturn["subversion"] = subversion.replacingOccurrences(of: "Satoshi:", with: "")
                let localaddresses = responseDictionary["localaddresses"] as! NSArray
                
                if localaddresses.count > 0 {
                    for address in localaddresses {
                        let dict = address as! NSDictionary
                        let p2pAddress = dict["address"] as! String
                        let port = dict["port"] as! Int
                        
                        if p2pAddress.contains("onion") {
                            self?.dictToReturn["p2pOnionAddress"] = p2pAddress + ":" + "\(port)"
                        }
                    }
                }
                
                let networks = responseDictionary["networks"] as! NSArray
                
                for network in networks {
                    let dict = network as! NSDictionary
                    let name = dict["name"] as! String
                    
                    if name == "onion" {
                        let reachable = dict["reachable"] as! Bool
                        self?.dictToReturn["reachable"] = reachable
                    }
                }
                
                completion()
                
            case .failure(let error):
                self?.errorBool = true
                self?.errorDescription = "\(error)"
                completion()
            }
        }
    }
    
    func loadSectionZero(completion: @escaping () -> Void) {
        print("loadSectionZero")
        
        if !walletDisabled {
            TorRPC.instance.executeRPCCommand(walletName: wallet.name, method: .listunspent, param: "0") { [weak self] (result) in
                switch result {
                case .success(let response):
                    // NOTE: Previously had a switch statment to handle differing cases
                    let responseArray = response as! NSArray
                    self?.parseUtxos(utxos: responseArray)
                    completion()
                case .failure(let error):
                    // TODO: Remove these two?
                    self?.errorBool = true
                    self?.errorDescription = "\(error)"
                    
                    print("errorDescription = \(self!.errorDescription)")
                    completion() // Temporarily thrown in
                    
                    // FIXME: HANDLE THIS EXCEPTION
//                    if self!.errorDescription.contains("Requested wallet does not exist or is not loaded") {
//
//                        // possibly changed from mainnet to testnet or vice versa, try and load once
//
//                        reducer.errorDescription = ""
//                        reducer.errorBool = false
//                        self?.errorDescription = ""
//                        self?.errorBool = false
//
//                        reducer.makeCommand(walletName: wallet.name, command: .loadwallet, param: "\"\(wallet.name)\"") {
//                            if !reducer.errorBool {
//                                reducer.makeCommand(walletName: self.wallet.name, command: .listunspent,
//                                                    param: "0",
//                                                    completion: getResult)
//                            } else {
//                                self.errorBool = true
//                                self.errorDescription = "Wallet does not exist, maybe you changed networks? If you want to use the app on a different network please delete the app and install again"
//                                completion()
//                            }
//                        }
//                    } else {
//                         completion()
//                    }
                }
            }
        } else {
            dictToReturn["coldBalance"] = "disabled"
            dictToReturn["unconfirmedBalance"] = "disabled"
            completion()
        }
        
    }
    
    func loadSectionTwo(completion: @escaping () -> Void) {
        print("loadSectionTwo")
        
        var walletName = ""
        
        if wallet != nil {
            walletName = wallet!.name
        }
        
        // Runs commands in succession
        func runCommand(method: BTC_CLI_COMMAND, param: String) {
            TorRPC.instance.executeRPCCommand(walletName: walletName, method: method, param: param) { [weak self] (result) in
                switch result {
                case .success(let response):
                    switch method {
                    case BTC_CLI_COMMAND.estimatesmartfee:
                        let responseDictionary = response as! NSDictionary
                        if let feeRate = responseDictionary["feerate"] as? Double {
                            let btcperbyte = feeRate / 1000
                            let satsperbyte = (btcperbyte * 100000000).avoidNotation
                            self?.dictToReturn["feeRate"] = "\(satsperbyte) s/b"
                        } else {
                            if let errors = responseDictionary["errors"] as? NSArray {
                                self?.dictToReturn["feeRate"] = "\(errors[0] as! String)"
                            }
                        }
                        
                        // Last command to be run
                        completion()
                        
                    case BTC_CLI_COMMAND.getmempoolinfo:
                        let responseDictionary = response as! NSDictionary
                        self?.dictToReturn["mempoolCount"] = responseDictionary["size"] as! Int
                        let feeRate = UserDefaults.standard.integer(forKey: "feeTarget")
                        
                        runCommand(method: .estimatesmartfee, param: "\(feeRate)")
                    case BTC_CLI_COMMAND.uptime:
                        self?.dictToReturn["uptime"] = Int(response as! Double)
                        
                        runCommand(method: .getmempoolinfo, param: "")
                    case BTC_CLI_COMMAND.getmininginfo:
                        let miningInfo = response as! NSDictionary
                        self?.parseMiningInfo(miningInfo: miningInfo)
                        
                        runCommand(method: .uptime, param: "")
    //                case BTC_CLI_COMMAND.getnetworkinfo.rawValue:
    //
    //                    let networkInfo = reducer.dictToReturn
    //                    parseNetworkInfo(networkInfo: networkInfo)
                    case BTC_CLI_COMMAND.getpeerinfo:
                        let peerInfo = response as! NSArray
                        self?.parsePeerInfo(peerInfo: peerInfo)
                        
                        runCommand(method: .getmininginfo, param: "")
                    case BTC_CLI_COMMAND.getblockchaininfo:
                        let blockchainInfo = response as! NSDictionary
                        self?.parseBlockchainInfo(blockchainInfo: blockchainInfo)
                        
                        runCommand(method: .getpeerinfo, param: "")
                    default:
                        break
                    }
                case .failure(let error):
                    print(error)
                    completion()
                }
            }
        }
        
        runCommand(method: .getblockchaininfo, param: "")
    }
    
    // TODO: Determine if this needs to be a block/callback
    func loadSectionThree(completion: @escaping () -> Void) {
        print("loadSectionThree")
        
        if !walletDisabled {
            TorRPC.instance.executeRPCCommand(walletName: wallet!.name, method: .listtransactions, param: "\"*\", 50, 0, true") { [weak self] (result) in
                switch result {
                case .success(let response):
                    // NOTE: previously had a check to ensure .listtransactions was called via switch statement (unknown why), then proceed like so.
                    let transactions = response as! NSArray
                    self?.parseTransactions(transactions: transactions)
                    completion()
                case .failure:
                    completion()
                }
            }
        } else {
            arrayToReturn = []
            completion()
        }
    }
    
    // MARK: Section 0 parsers
    
    func parseUtxos(utxos: NSArray) {
        
        var amount = 0.0
        
        for utxo in utxos {
            
            let utxoDict = utxo as! NSDictionary
            let spendable = utxoDict["spendable"] as! Bool
            let confirmations = utxoDict["confirmations"] as! Int
            
            if !spendable {
                
                let balance = utxoDict["amount"] as! Double
                amount += balance
                
            }
            
            if confirmations < 1 {
                
                dictToReturn["unconfirmed"] = true
                
            }
            
        }
        
        if amount == 0.0 {
            
            dictToReturn["coldBalance"] = "0.0"
            
        } else {
            
            dictToReturn["coldBalance"] = "\((round(100000000*amount)/100000000).avoidNotation)"
            
        }
        
    }
    
    // MARK: Section 1 parsers
    
    func parseMiningInfo(miningInfo: NSDictionary) {
        
        let hashesPerSecond = miningInfo["networkhashps"] as! Double
        let exahashesPerSecond = hashesPerSecond / 1000000000000000000
        dictToReturn["networkhashps"] = Int(exahashesPerSecond).withCommas()
        
    }
    
    func parseBlockchainInfo(blockchainInfo: NSDictionary) {
        
        if let currentblockheight = blockchainInfo["blocks"] as? Int {
            
            dictToReturn["blocks"] = currentblockheight
            
        }
        
        if let difficultyCheck = blockchainInfo["difficulty"] as? Double {
            
            
            dictToReturn["difficulty"] = "\(Int(difficultyCheck / 1000000000000).withCommas()) trillion"
            
        }
        
        if let sizeCheck = blockchainInfo["size_on_disk"] as? Int {
            
            dictToReturn["size"] = "\(sizeCheck/1000000000) gb"
            
        }
        
        if let progressCheck = blockchainInfo["verificationprogress"] as? Double {
            
            dictToReturn["progress"] = "\(Int(progressCheck*100))%"
            
        }
        
        if let chain = blockchainInfo["chain"] as? String {
            
            dictToReturn["chain"] = chain
            
        }
        
        if let pruned = blockchainInfo["pruned"] as? Bool {
            
            dictToReturn["pruned"] = pruned
            
        }
        
    }
    
    func parsePeerInfo(peerInfo: NSArray) {
        
        var incomingCount = 0
        var outgoingCount = 0
        
        for peer in peerInfo {
            
            let peerDict = peer as! NSDictionary
            
            let incoming = peerDict["inbound"] as! Bool
            
            if incoming {
                
                incomingCount += 1
                dictToReturn["incomingCount"] = incomingCount
                
            } else {
                
                outgoingCount += 1
                dictToReturn["outgoingCount"] = outgoingCount
                
            }
            
        }
        
    }
    
    func parseNetworkInfo(networkInfo: NSDictionary) {
        
        
        
    }
    
    func parseTransactions(transactions: NSArray) {
        
        var transactionArray = [[String:Any]]()
        self.arrayToReturn.removeAll()
        
        for item in transactions {
            
            if let transaction = item as? NSDictionary {
                
                var label = String()
                var replaced_by_txid = String()
                var isCold = false
                
                let address = transaction["address"] as? String ?? ""
                let amount = transaction["amount"] as? Double ?? 0.0
                let amountString = amount.avoidNotation
                let confsCheck = transaction["confirmations"] as? Int ?? 0
                let confirmations = String(confsCheck)
                
                if let replaced_by_txid_check = transaction["replaced_by_txid"] as? String {
                    
                    replaced_by_txid = replaced_by_txid_check
                    
                }
                
                if let labelCheck = transaction["label"] as? String {
                    
                    label = labelCheck
                    
                    if labelCheck == "" {
                        
                        label = ""
                        
                    }
                    
                    if labelCheck == "," {
                        
                        label = ""
                        
                    }
                    
                } else {
                    
                    label = ""
                    
                }
                
                let secondsSince = transaction["time"] as? Double ?? 0.0
                let rbf = transaction["bip125-replaceable"] as? String ?? ""
                let txID = transaction["txid"] as? String ?? ""
                
                let date = Date(timeIntervalSince1970: secondsSince)
                dateFormatter.dateFormat = "MMM-dd-yyyy HH:mm"
                let dateString = dateFormatter.string(from: date)
                
                if let boolCheck = transaction["involvesWatchonly"] as? Bool {
                    
                    isCold = boolCheck
                    
                }
                
                
                                
                transactionArray.append(["address": address,
                                         "amount": amountString,
                                         "confirmations": confirmations,
                                         "label": label,
                                         "date": dateString,
                                         "rbf": rbf,
                                         "txID": txID,
                                         "replacedBy": replaced_by_txid,
                                         "involvesWatchonly":isCold,
                                         "selfTransfer":false,
                                         "remove":false])
                
            }
            
        }
        
        // process self transfers
                    
        for (i, tx) in transactionArray.enumerated() {
            
            let amount = Double(tx["amount"] as! String)!
            let txID = tx["txID"] as! String
            
            for (x, transaction) in transactionArray.enumerated() {
                
                let amountToCompare = Double(transaction["amount"] as! String)!
                
                if x != i && txID == (transaction["txID"] as! String) {
                    
                    if amount + amountToCompare == 0 && amount > 0 {
                        
                        transactionArray[i]["selfTransfer"] = true
                        
                    } else if amount + amountToCompare == 0 && amount < 0 {
                        
                        transactionArray[i]["remove"] = true
                        
                    }
                    
                }
                
            }
            
        }
                    
        for tx in transactionArray {
            
            if !(tx["remove"] as! Bool) {
                
                arrayToReturn.append(tx)
                
            }
            
        }
        
    }
    
}
