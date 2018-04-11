//
//  ConnectionChecker.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 22/03/2018.
//  Copyright © 2018 Dayan Yonnatan. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ConnectionChecker {
    
    var alertController:UIAlertController?
    var noConnectionTimer:Timer?
    var checkConnectionCount:Int = 0
    
    var appDelegate:AppDelegate!
    var uid:String?
    
    init(appdelegate:AppDelegate) {
        self.appDelegate = appdelegate
        _ = checkInternetConnection
    }
    init(appdelegate:AppDelegate, uid:String) {
        self.appDelegate = appdelegate
        self.uid = uid
        
        _ = checkInternetConnection
    }
    deinit {
        if self.uid != nil {
            self.uid = nil
        }
        self.appDelegate = nil
        self.alertController = nil
        noConnectionTimer?.invalidate()
        noConnectionTimer = nil
    }
    
    private lazy var checkInternetConnection: Void = {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            self.checkConnection()
        })
    }()
    
    // MARK: Setting users connection status - Only works if module has received a UID at init
    func setOnline() {
        if let uid = self.uid {
        let connectedUsersRef = Database.database().reference().child("connected_users")
        connectedUsersRef.onDisconnectUpdateChildValues([uid:false] as [String:Bool])
        connectedUsersRef.updateChildValues([uid:true] as [String:Bool])
        }
    }
    func setOffline() {
        if let uid = self.uid {
        let connectedUsersRef = Database.database().reference().child("connected_users")
        connectedUsersRef.updateChildValues([uid:false] as [String:Bool])
        }
    }
    
    // MARK: Disable/Enable User Interactions
    func disableUserInteraction() {
        self.appDelegate.window?.rootViewController?.view.isUserInteractionEnabled = false
    }
    func enableUserInteraction() {
        self.appDelegate.window?.rootViewController?.view.isUserInteractionEnabled = true
    }
    
    // MARK: AlertController methods
    func removeCheckConnectionDialog() {
        alertController?.dismiss(animated: true, completion: nil)
    }
    func presentCustom(viewController:UIViewController) {
        if let navController = self.appDelegate.window?.rootViewController as? UINavigationController {
            navController.visibleViewController?.present(viewController, animated: true, completion: nil)
            return
        }
        if let sourceViewController = self.appDelegate.window?.rootViewController {
            sourceViewController.present(viewController, animated: true, completion: nil)
            return
        }
    }
    
    @objc func showNoConnectionError() {
        alertController = UIAlertController.init(title: "No Internet Connection", message: "Unable to connect to server, \nPlease make sure you are connected to WiFi or a 3G/4G network", preferredStyle: .alert)
        alertController?.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (action) in
            self.checkConnectionAfterShortWait()
        }))
        alertController?.addAction(UIAlertAction(title: "Close app", style: .destructive, handler: { (action) in
            exit(0)
        }))
        self.presentCustom(viewController: alertController!)
    }
    
    
    // MARK: Connection checking functions
    func checkConnection() {
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                self.noConnectionTimer?.invalidate()
                self.removeCheckConnectionDialog()
                self.enableUserInteraction()
                self.setOnline()
            } else {
                self.noConnectionTimer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(self.showNoConnectionError), userInfo: nil, repeats: false)
                //self.disableUserInteraction()
            }
        })
    }
    
    func checkConnectionOnce() {
        let connectedReference = Database.database().reference(withPath: ".info/connected")
        connectedReference.observeSingleEvent(of: .value, with: { (snapshot) in
            if let connected = snapshot.value as? Bool {
                if connected == true {
                    self.noConnectionTimer?.invalidate()
                    self.enableUserInteraction()
                    self.setOnline()
                    self.removeCheckConnectionDialog()
                } else {
                    if self.checkConnectionCount == 0 {
                        self.checkConnectionCount += 1
                        self.checkConnectionOnce()
                        print("Checking connection again.")
                    } else {
                        //self.disableUserInteraction()
                        self.noConnectionTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.showNoConnectionError), userInfo: nil, repeats: false)
                    } }
            } else {
                //self.disableUserInteraction()
                self.noConnectionTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.showNoConnectionError), userInfo: nil, repeats: false)
            } })
    }
    
    func checkConnectionAfterShortWait() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.checkConnectionOnce()
        }
    }
    
    
}
