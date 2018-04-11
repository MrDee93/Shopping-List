//
//  ShoppingListVC.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 23/06/2017.
//  Copyright © 2017 Dayan Yonnatan. All rights reserved.
//

import UIKit

class ShoppingListVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UpdateTableDelegate, DatabaseUpdateDelegate {
    
    @IBOutlet var tableView:UITableView!
    var countOfRows:Int = 1 // To keep extra rows available
    var listController:ListController? // This controller manages the data fetching and updating
    var currentID:String? // Current Shopping List ID
    var arrayOfItems = [Item]() // Array of Items retrieved from the list
    var existingListID:String? // This is used to send the existing Shopping List ID to this viewcontroller.
    
    var listName:String?
    
    @IBAction func clearAllButton() {
        for item in arrayOfItems {
            print(item.name)
        }
    }
    
    @IBAction func deleteListButton() {
        print(arrayOfItems.count)
    }
    
    
    func getShareButton() -> UIBarButtonItem {
        let barbuttonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(shareButtonTapped(_:)))
        return barbuttonItem
    }
    func setupList() {
        if existingListID != nil {
            self.currentID = existingListID
        } else {
            self.currentID = listController?.getListID()
        }
        if let name = listName {
            self.navigationItem.title = name
        } else {
            self.navigationItem.title = "List: \(self.currentID!)"
            print("No name")
        }
        if let listid = self.currentID, let listname = listName {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.addListToDB(name: listname, id: listid)
            print("Added list to DB")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupList()
        
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
        self.tableView.reloadData()
    }
    
    var previousText:String?
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text?.isEmpty == false {
            textField.tag = 1
            previousText = textField.text
        } else {
            textField.tag = 0
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == "" || textField.text == " " || textField.text == "   " {
            textField.tag = 0
            textField.text = nil
            self.reloadData()
            return
        }
        if textField.tag == 1 {
            if let previousItemName = previousText {
                listController?.updateItemNameFor(oldItemName: previousItemName, newItemName: textField.text!)
            }
        }
        else {
            createItem(name: textField.text!)
            textField.tag = 1
        }
        defer {
            previousText = nil
        }
    }
    func createItem(name:String) {
        let newItem = Item(name: name, purchased: false)
        
        listController?.addItem(item: newItem)
        self.arrayOfItems.append(newItem)
        self.createNewRow()
    }
    
    func findAndRemoveItem(itemName:String) {
        var index = 0
        for item in arrayOfItems {
            
            if item.name?.compare(itemName) == ComparisonResult.orderedSame {
                arrayOfItems.remove(at: index)
                print("Removed item at index: ", index)
            }
            index = index + 1
        }
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let itemName = getItemNameFromIndexpath(indexPath: indexPath)
            
            listController?.removeItem(itemName: itemName)
            findAndRemoveItem(itemName: itemName)
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
    func getItemNameFromIndexpath(indexPath:IndexPath) -> String {
        let cell = self.tableView.cellForRow(at: indexPath) as! ItemTVC
        return cell.textField.text!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ItemTVC
        
        cell.textField.text = nil
        cell.delegate = self
        cell.textField.delegate = self
        cell.textField.inputAccessoryView = self.inputAccessoryViewOfTextField
        cell.enableRow()
        
        /*
        if(indexPath.row == (arrayOfItems.count + self.countOfRows) - 1) {
            cell.disableRow()
        } else {
            cell.enableRow()
            cell.textField.placeholder = "Add item"
            cell.textField.autocorrectionType = .no
            cell.textField.autocapitalizationType = .sentences
        }*/
        if (indexPath.row == (arrayOfItems.count + self.countOfRows) - 1) {
            cell.enableRow()
            cell.textField.placeholder = "Add item"
            cell.textField.autocorrectionType = .no
            cell.textField.autocapitalizationType = .sentences
        }
        if indexPath.row < (arrayOfItems.count) {
            
            let item = arrayOfItems[indexPath.row]
            cell.item = item
            cell.textField.text = item.name
            if let purchased = item.purchased {
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
        
        print("Item is index ", indexOfItem as Any)
        
        if indexOfItem != nil {
            let itemReference = arrayOfItems[indexOfItem!] as Item
            
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
        self.view.isUserInteractionEnabled = false
        print("Beginning to update DB")
        
        DispatchQueue.global(qos: .background).async {
            self.arrayOfItems.removeAll()
            self.arrayOfItems = dataArray
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }

        self.view.isUserInteractionEnabled = true
        print("Completed updating")
    }
    func reloadData() {
        self.tableView.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfItems.count + self.countOfRows
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func shareButtonTapped(_ sender:UIBarButtonItem) {
        let shareOptionsController = UIAlertController(title: "Share", message: "Select a Sharing method", preferredStyle: .actionSheet)
        
        let copyClipboard = UIAlertAction(title: "Copy Shopping ID to Clipboard", style: .default) { (action) in
            self.copyToClipboard()
        }
        let shareMessage = UIAlertAction(title: "Send as Message", style: .default) { (action) in
            self.sendAsMessage()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        
        shareOptionsController.addAction(copyClipboard)
        shareOptionsController.addAction(shareMessage)
        shareOptionsController.addAction(cancelAction)

        shareOptionsController.popoverPresentationController?.barButtonItem = sender
        self.present(shareOptionsController, animated: true) { 
            // When done....
        }
        print("Displaying options..")
    }
    
    
    func copyToClipboard() {
        //UIPasteboard.general.string = self.currentID
        guard let currentID = self.currentID else {
            return
        }
        //let clipboardString = String("ShoppingListDY://?" + currentID)
        
        UIPasteboard.general.string = currentID
        
    }
    
    
    func sendAsMessage() {
        guard let currentID = self.currentID else {
            return
        }

        let listLink = String("ShoppingListDY://?" + currentID)
        
        self.sendMessageWithID(listLink!)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
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
