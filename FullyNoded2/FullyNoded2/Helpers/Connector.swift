//
//  Connector.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class Connector {
    
    var torClient:TorClient!
    var torConnected:Bool!
    var errorBool:Bool!
    var errorDescription:String!
    
    func connectTor(completion: @escaping () -> Void) {
        
        self.torClient = TorClient.sharedInstance
        
        func completed() {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                
                if self.torClient.isOperational {
                    print("Tor connected")
                    
                    self.torConnected = true
                    completion()
                    
                } else {
                    
                    print("error connecting tor")
                    self.torConnected = false
                    completion()
                    
                }
                
            })
            
        }
        
        if self.torClient.isRefreshing {
            
            self.torClient.restart(completion: completed)
            
        } else {
            
            self.torClient.start(completion: completed)
            
        }
        
    }
    
}
