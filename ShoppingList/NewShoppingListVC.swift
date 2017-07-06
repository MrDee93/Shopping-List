//
//  NewShoppingListVC.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 23/06/2017.
//  Copyright © 2017 Dayan Yonnatan. All rights reserved.
//

import UIKit

class NewShoppingListVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UpdateTableDelegate, DatabaseUpdateDelegate {
    
    @IBOutlet var tableView:UITableView!
    var countOfRows:Int = 2
    var listController:ListController?
    var currentUser:String?
    
    // Firebase
    var currentID:String?
    
    var arrayOfItems = [Item]()
    
    var newListOption:Bool?
    var existingListID:String?
    
    func getShareButton() -> UIBarButtonItem {
        let barbuttonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(shareButtonTapped))
        return barbuttonItem
    }
    
    /*let shareButton: UIBarButtonItem = {
        let barbuttonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(shareButtonTapped()))
        return barbuttonItem
    }()*/
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if newListOption == nil {
        newListOption = true
        }
        
        if existingListID != nil && newListOption == false {
            self.currentID = existingListID
            self.navigationItem.title = "List: \(existingListID!)"
            
            if listController == nil {
            listController = ListController(user: currentUser!)
            listController?.connectToListWith(id: existingListID!)
            }
        } else {
            if listController == nil {
                listController = ListController(user: currentUser!)
                listController?.createNewList()
            }
            self.currentID = listController?.getListID()
            self.navigationItem.title = "List: \(self.currentID!)"
        }
        if listController != nil {
            listController?.databaseUpdateDelegate = self
        }
        print("Count of array of items ",self.arrayOfItems.count)
        // REFRESH DATA AFTER CHANGING A CELL INFO... MAYBE USE DEFAULTCENTER POST NOTIFICATION TO UPDATE AND CREATE NEW ROW

        self.navigationItem.rightBarButtonItem = self.getShareButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Delegate method
    func createNewRow() {
        //self.countOfRows += 1
        self.tableView.reloadData()
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 1 {
            return
        }
        if textField.text != "" || textField.text != " " {
            createItem(name: textField.text!)
            textField.tag = 1
        }
    }
    func createItem(name:String) {
        let newItem = Item(name: name, purchased: false)
        
        listController?.addItem(item: newItem)
        self.arrayOfItems.append(newItem)
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            //print("DELETE ATTEMPT!! row ", indexPath.row)
            self.countOfRows -= 1
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
        }
    }
    lazy var inputAccessoryViewOfTextField: UIToolbar? = {
        let toolbarDone = UIToolbar.init()
        toolbarDone.sizeToFit()
        
        let flexiSpace = UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let barButtonDone = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(handleDone))
        
        toolbarDone.items = [flexiSpace, barButtonDone]
        
        return toolbarDone
    }()
    func handleDone() {
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ItemTVC
        
        cell.delegate = self
        cell.textField.delegate = self
        cell.textField.inputAccessoryView = self.inputAccessoryViewOfTextField
        
        if(indexPath.row == (arrayOfItems.count + self.countOfRows) - 1) {
            cell.disableRow()
        } else {
            cell.enableRow()
            cell.textField.placeholder = "Add item"
            cell.textField.autocorrectionType = .no
            cell.textField.autocapitalizationType = .words
        }
        
        if indexPath.row < (arrayOfItems.count) {
            print("Item number ", indexPath.row)
            let item = arrayOfItems[indexPath.row]
            print("purchase status: ", item.purchased)
            cell.item = item
            cell.textField.text = item.name
            if let purchased = item.purchased {
                print("Item is ", purchased)
                if(purchased) {
                    cell.setTicked()
                } else {
                    cell.setUnticked()
                }
            }
        }
        
        return cell
    }
    func changeTickInfo(tickInfo:TickInfo, _ itemName:String) {
        if itemName == " " || itemName == "" {
            return
        }
        print("Tick info changed for ", itemName)
        updateItem(itemName: itemName, tickInfo: tickInfo)
    }
    func updateItem(itemName:String, tickInfo:TickInfo) {
        let indexOfItem = arrayOfItems.index(where: {$0.name == itemName})
        
        print("Item is index ", indexOfItem)
        
        if indexOfItem != nil {
            var itemReference = arrayOfItems[indexOfItem!] as Item
            
            if tickInfo == .Ticked {
                itemReference.purchased = true
            } else {
                itemReference.purchased = false
            }
            print("Item ref: ", itemReference.name!)
            
            listController?.updateItemInfo(item: itemReference)
        }
        
    }
    
    
    // database update delegate
    func updateListWith(dataArray:[Item]) {
        //self.view.isUserInteractionEnabled = false
        
        //arrayOfItems.removeAll()
        
        
        for item in dataArray {
            
            let newitem = Item(name: item.name!, purchased: item.purchased!)
            
            //arrayOfItems.append(newItem)
            print("Created \(item.name!) with \(item.purchased!)")
        }
        
        //self.tableView.reloadData()
        //self.view.isUserInteractionEnabled = true
        
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return countOfRows
        return arrayOfItems.count + self.countOfRows
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func shareButtonTapped() {
        let shareOptionsController = UIAlertController(title: "Share", message: "Select a Sharing method", preferredStyle: .actionSheet)
        
        let copyClipboard = UIAlertAction(title: "Copy to Clipboard", style: .default) { (action) in
            self.copyToClipboard()
        }
        let shareMessage = UIAlertAction(title: "Send as Message", style: .default) { (action) in
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        
        shareOptionsController.addAction(copyClipboard)
        //shareOptionsController.addAction(shareMessage)
        shareOptionsController.addAction(cancelAction)

        self.present(shareOptionsController, animated: true) { 
            // When done....
        }
        print("Displaying options..")
    }
    
    
    func copyToClipboard() {
        UIPasteboard.general.string = self.currentID
    }
    
    func sendAsMessage() {
        // not written up yet as too much code.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
