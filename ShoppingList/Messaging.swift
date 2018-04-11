//
//  Messaging.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 24/03/2018.
//  Copyright © 2018 Dayan Yonnatan. All rights reserved.
//

import UIKit
import MessageUI

extension ShoppingListVC: MFMessageComposeViewControllerDelegate {
    
    func getMessageComposeVC(_ id:String) -> MFMessageComposeViewController {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self
        messageComposeVC.body = "Let\'s shop together! Tap the link to open my Shopping List: " + id
        return messageComposeVC
    }
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    func sendMessageWithID(_ id:String) {
        self.present(getMessageComposeVC(id), animated: true, completion: nil)
    }
    
}
