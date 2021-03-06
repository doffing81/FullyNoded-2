//
//  UTXOViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class UTXOViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tapQRGesture = UITapGestureRecognizer()
    var tapTextViewGesture = UITapGestureRecognizer()
    let refresher = UIRefreshControl()
    var utxoArray = [Any]()
    var address = ""
    var creatingView = ConnectingView()
    var isFirstTime = Bool()
    var utxo = NSDictionary()
    
    @IBOutlet var utxoTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        utxoTable.delegate = self
        utxoTable.dataSource = self
        utxoTable.tableFooterView = UIView(frame: .zero)
        refresh()
        
    }
    
    @objc func refresh() {
        
        addSpinner()
        utxoArray.removeAll()
        
        executeNodeCommand(method: .listunspent,
                           param: "0")
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return utxoArray.count
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "utxoCell", for: indexPath)
        
        if utxoArray.count > 0 {
            
            let dict = utxoArray[indexPath.section] as! NSDictionary
            let address = cell.viewWithTag(1) as! UILabel
            let txId = cell.viewWithTag(2) as! UILabel
            let amount = cell.viewWithTag(4) as! UILabel
            let vout = cell.viewWithTag(6) as! UILabel
            let solvable = cell.viewWithTag(7) as! UILabel
            let confs = cell.viewWithTag(8) as! UILabel
            let safe = cell.viewWithTag(9) as! UILabel
            let spendable = cell.viewWithTag(10) as! UILabel
            let label = cell.viewWithTag(11) as! UILabel
            let infoButton = cell.viewWithTag(12) as! UIButton
            txId.adjustsFontSizeToFitWidth = true
            
            infoButton.addTarget(self, action: #selector(getInfo(_:)), for: .touchUpInside)
            infoButton.restorationIdentifier = "\(indexPath.section)"
            
            for (key, value) in dict {
                
                let keyString = key as! String
                
                switch keyString {
                    
                case "address":
                    
                    address.text = "\(value)"
                    
                case "txid":
                    
                    txId.text = "txid: \(value)"
                    
                case "amount":
                    
                    let dbl = rounded(number: value as! Double)
                    amount.text = dbl.avoidNotation
                    
                case "vout":
                    
                    vout.text = "vout #\(value)"
                    
                case "solvable":
                    
                    if (value as! Int) == 1 {
                        
                        solvable.text = "Solvable"
                        solvable.textColor = .systemBlue
                        
                    } else if (value as! Int) == 0 {
                        
                        solvable.text = "Not Solvable"
                        solvable.textColor = .systemRed
                        
                    }
                    
                case "confirmations":
                    
                    if (value as! Int) == 0 {
                     
                        confs.textColor = .systemRed
                        
                    } else {
                        
                        confs.textColor = .systemGreen
                        
                    }
                    
                    confs.text = "\(value) confs"
                    
                case "safe":
                    
                    if (value as! Int) == 1 {
                        
                        safe.text = "Safe"
                        safe.textColor = .systemGreen
                        
                    } else if (value as! Int) == 0 {
                        
                        safe.text = "Not Safe"
                        safe.textColor = .systemOrange
                        //cell.backgroundColor = .systemRed
                        
                    }
                    
                case "spendable":
                    
                    if (value as! Int) == 1 {
                        
                        spendable.text = "Spendable"
                        spendable.textColor = .systemGreen
                        
                    } else if (value as! Int) == 0 {
                        
                        spendable.text = "COLD"
                        spendable.textColor = .systemBlue
                        
                    }
                    
                case "label":
                    
                    label.text = (value as! String)
                    
                default:
                    
                    break
                    
                }
                
            }
            
        }
        
        return cell
        
    }
    
    @objc func getInfo(_ sender: UIButton) {
     
        let index = Int(sender.restorationIdentifier!)!
        utxo = utxoArray[index] as! NSDictionary
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            self.performSegue(withIdentifier: "utxoInfo", sender: self)
            
        }
    }
    
//    func lockUTXO(txid: String, vout: Int) {
//        
//        let param = "false, ''[{\"txid\":\"\(txid)\",\"vout\":\(vout)}]''"
//        
//        executeNodeCommand(method: .lockunspent,
//                           param: param)
//        
//    }
    
//    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//
//        let utxos = utxoArray as NSArray
//        let utxo = utxos[indexPath.section] as! NSDictionary
//        let txid = utxo["txid"] as! String
//        let vout = utxo["vout"] as! Int
//
//        let contextItem = UIContextualAction(style: .destructive, title: "Lock") {  (contextualAction, view, boolValue) in
//
//            self.lockUTXO(txid: txid, vout: vout)
//
//        }
//
//        let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
//        contextItem.backgroundColor = .systemRed
//
//        return swipeActions
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //let cell = utxoTable.cellForRow(at: indexPath)
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        
    }
    
    func parseUnspent(utxos: NSArray) {
        
        if utxos.count > 0 {
            
            self.utxoArray = (utxos as NSArray).sortedArray(using: [NSSortDescriptor(key: "confirmations", ascending: true)]) as! [[String:AnyObject]]
            
            DispatchQueue.main.async {
                
                self.removeSpinner()
                self.utxoTable.reloadData()
                
            }
            
        } else {
            
            self.removeSpinner()
            
            displayAlert(viewController: self,
                         isError: true,
                         message: "No UTXO's")
            
        }
        
    }
    
    func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
        
        let reducer = Reducer()
        
        func getResult() {
            
            if !reducer.errorBool {
                
                switch method {
                    
                case .listunspent:
                    
                    if let resultArray = reducer.arrayToReturn {
                        
                        parseUnspent(utxos: resultArray)
                        
                    }
                    
                default:
                    
                    break
                    
                }
                
            } else {
                
                DispatchQueue.main.async {
                    
                    self.removeSpinner()
                    
                    displayAlert(viewController: self,
                                 isError: true,
                                 message: reducer.errorDescription)
                                        
                }
                
            }
            
        }
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil && !error {
                
                reducer.makeCommand(walletName: wallet!.name, command: method,
                                    param: param,
                                    completion: getResult)
                
            }
            
        }
                
    }
    
    func removeSpinner() {
        
        DispatchQueue.main.async {
            
            self.refresher.endRefreshing()
            self.creatingView.removeConnectingView()
            
        }
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    func addSpinner() {
        
        DispatchQueue.main.async {
            
            self.creatingView.addConnectingView(vc: self,
                                                description: "Getting UTXOs")
            
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            
//        case "goToLocked":
//
//            if let vc = segue.destination as? LockedViewController {
//
//                vc.lockedArray = self.lockedArray
//
//            }
            
        case "utxoInfo":
            
            if let vc = segue.destination as? UtxoInfoViewController {
             
                vc.utxo = self.utxo
                
            }
            
        default:
            
            break
            
        }
        
    }
    
}

extension Int {
    
    var avoidNotation: String {
        
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 8
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(for: self) ?? ""
        
    }
}



