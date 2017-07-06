//
//  ViewController.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 23/06/2017.
//  Copyright © 2017 Dayan Yonnatan. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, ShoppingListSearchDelegate {

    @IBOutlet var displayNameTextField:UITextField!
    
    var existingListViewController:NewShoppingListVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupBackgroundTap()
    }
    override func viewDidAppear(_ animated: Bool) {
        if existingListViewController != nil {
            existingListViewController = nil
        }
        print("View did appear")
    }
    
    @IBAction func createNewList() {
        existingListViewController = self.storyboard?.instantiateViewController(withIdentifier: "NewShoppingListVC") as? NewShoppingListVC
        existingListViewController?.existingListID = nil
        existingListViewController?.newListOption = true
        existingListViewController?.currentUser = self.displayNameTextField.text
        
        existingListViewController?.listController = ListController(user: self.displayNameTextField.text!)
        existingListViewController?.listController?.createNewList()
        
        self.navigationController?.pushViewController(existingListViewController!, animated: true)
    }
    
    @IBAction func openExistingList() {
        if self.displayNameTextField.text == "" || self.displayNameTextField.text == " " {
            let alertController = UIAlertController(title: "ERROR", message: "Please enter a display name before continuing", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .destructive, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        } else {
        let alertController = UIAlertController(title: "Open an existing List", message: "Enter list ID", preferredStyle: .alert)
        alertController.addTextField { (textfield) in
            
        }
        
        alertController.addAction(UIAlertAction(title: "Open", style: .default, handler: { (action) in
            if let listID = alertController.textFields?.last?.text {
            if listID != "" || listID != " " {
                self.openListWith(id: listID)
            }
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func openListWith(id:String) {
        print("Opening list ", id)
        
        existingListViewController = self.storyboard?.instantiateViewController(withIdentifier: "NewShoppingListVC") as? NewShoppingListVC
        existingListViewController?.existingListID = id
        existingListViewController?.newListOption = false
        existingListViewController?.currentUser = self.displayNameTextField.text
        
        existingListViewController?.listController = ListController(user: self.displayNameTextField.text!)
        existingListViewController?.listController?.connectToListWith(id: id)
        existingListViewController?.listController?.listSearchDelegate = self
        
        
    }
    
    func foundListWith(dataArray: NSDictionary) {
        // first create array of data
        var arrayOfItems = [Item]()
        
        for item in dataArray {
            let theitem = item.value as! NSDictionary
            let purchased = theitem["purchased"] as! Bool
            let itemName = item.key as! String
            
            print("Item: \(itemName) purchased:\((purchased) ? "true" : "false")")
            let newItem = self.createNewItemWith(name: itemName, purchased: purchased)
            existingListViewController?.arrayOfItems.append(newItem)
            
        }
        
        self.navigationController?.pushViewController(existingListViewController!, animated: true)
        print("Count of items ", existingListViewController?.arrayOfItems.count)
    }
    func createNewItemWith(name:String, purchased:Bool) -> Item {
        let item = Item(name: name, purchased: purchased)
        return item
    }
    
    func unableToFindList() {
        let alertController = UIAlertController(title: "Unable to find list", message: "Unable to find the list..\nMake sure you copy and paste the ID exactly as it is", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .destructive, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
    func setupBackgroundTap() {
        let backgroundTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        self.view.addGestureRecognizer(backgroundTapRecognizer)
    }

    func endEditing() {
        self.view.endEditing(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newListSegue" {
            if displayNameTextField.text == "" {
                (segue.destination as! NewShoppingListVC).currentUser = "Anon"
            } else {
                (segue.destination as! NewShoppingListVC).currentUser = self.displayNameTextField.text
            }
        }
    }
}

