//
//  LockedViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class LockedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var lockedArray = NSArray()
    var helperArray = [[String:Any]]()
    let creatingView = ConnectingView()
    var selectedVout = Int()
    var selectedTxid = ""
    var ind = 0
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: .zero)
        
        DispatchQueue.main.async {
            
            self.creatingView.addConnectingView(vc: self,
                                                description: "Getting Locked UTXOs")
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        getHelperArray()
        
    }
    
    func getHelperArray() {
        
        helperArray.removeAll()
        
        ind = 0
        
        if lockedArray.count > 0 {
            
            for utxo in lockedArray {
                
                let dict = utxo as! NSDictionary
                let txid = dict["txid"] as! String
                let vout = dict["vout"] as! Int
                
                let helperDict = ["txid":txid,
                                  "vout":vout,
                                  "amount":0.0] as [String : Any]
                
                helperArray.append(helperDict)
                
            }
            
            getAmounts(i: ind)
            
        } else {
            
            DispatchQueue.main.async {
                
                self.tableView.reloadData()
                
                self.creatingView.removeConnectingView()
                
                displayAlert(viewController: self,
                             isError: true,
                             message: "No locked UTXO's")
                
            }
            
        }
        
    }
    
    func getAmounts(i: Int) {
        
        if i <= helperArray.count - 1 {
            
            selectedTxid = helperArray[i]["txid"] as! String
            selectedVout = helperArray[i]["vout"] as! Int
            
            executeNodeCommand(method: .getrawtransaction,
                               param: "\"\(selectedTxid)\", true")
            
        }
        
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return helperArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "lockedCell", for: indexPath)
        
        let amountLabel = cell.viewWithTag(1) as! UILabel
        let voutLabel = cell.viewWithTag(2) as! UILabel
        let txidLabel = cell.viewWithTag(3) as! UILabel
        
        let dict = helperArray[indexPath.row]
        let txid = dict["txid"] as! String
        let vout = dict["vout"] as! Int
        let amount = dict["amount"] as! Double
        
        amountLabel.text = "\(amount)"
        voutLabel.text = "vout #\(vout)"
        txidLabel.text = "txid" + " " + txid
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 113
        
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let utxo = helperArray[indexPath.row]
        let txid = utxo["txid"] as! String
        let vout = utxo["vout"] as! Int
        
        let contextItem = UIContextualAction(style: .destructive, title: "Unlock") {  (contextualAction, view, boolValue) in
            
            self.unlockUTXO(txid: txid, vout: vout)
            
        }
        
        let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
        contextItem.backgroundColor = .blue

        return swipeActions
    }
    
    func unlockUTXO(txid: String, vout: Int) {
        
        let param = "true, ''[{\"txid\":\"\(txid)\",\"vout\":\(vout)}]''"
        
        executeNodeCommand(method: BTC_CLI_COMMAND.lockunspent,
                           param: param)
        
    }
    
    #warning("TODO: Continue refactoring")
    func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil && !error {
               TorRPC.instance.executeRPCCommand(walletName: wallet!.name, method: method, param: param) { [weak self] (result) in
                   switch result {
                   case .success(let response):
                    
                       switch method {
                       case .getrawtransaction:
                           let responseDictionary = response as! NSDictionary
                           let outputs = responseDictionary["vout"] as! NSArray
                           
                           for (i, outputDict) in outputs.enumerated() {
                               
                                let output = outputDict as! NSDictionary
                                let value = output["value"] as! Double
                                let vout = output["n"] as! Int
                               
                                if vout == self!.selectedVout {
                                    self?.helperArray[self!.ind]["amount"] = value
                                    self?.ind += 1
                                }
                               
                                if i + 1 == outputs.count {
                                   if self!.ind <= self!.helperArray.count - 1 {
                                       self?.getAmounts(i: self!.ind)
                                   } else {
                                       DispatchQueue.main.async {
                                           self?.tableView.reloadData()
                                           self?.creatingView.removeConnectingView()
                                       }
                                    }
                                }
                            }
                    case .listlockunspent:
                        self?.lockedArray = response as! NSArray
                        self?.getHelperArray()
                    case .lockunspent:
                           let responseDouble = response as! Double
                           if responseDouble == 1 {
                               displayAlert(viewController: self!, isError: false, message: "UTXO is unlocked and can be selected for spends")
                           } else {
                               displayAlert(viewController: self!, isError: true, message: "Unable to unlock that UTXO")
                           }
                           self?.helperArray.removeAll()
                           
                           self?.executeNodeCommand(method: .listlockunspent, param: "")
                           
                           DispatchQueue.main.async {
                               self?.creatingView.addConnectingView(vc: self!, description: "Refreshing")
                           }
                       default:
                           break
                       }
                   case .failure(let error):
                    
                       DispatchQueue.main.async {
                           self?.creatingView.removeConnectingView()
                           displayAlert(viewController: self!, isError: true, message: "\(error)")
                       }
                   }
               }
            }
        }
    }
}
