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
    var listController:ListController? // This controller manages the data fetching and updating
    var currentID:String? // Current Shopping List ID
     var arrayOfItems = [Item]() // Array of Items retrieved from the list
    var existingListID:String? // This is used to send the existing Shopping List ID to this viewcontroller.
    
    var listName:String?
    
    func sortList() {
        arrayOfItems.sort{ (firstItem, nextItem) -> Bool in
            if firstItem.purchased == true {
                return false
            } else if nextItem.purchased == true {
                return true
            }
            return true
        }
        self.reloadData()
    }
    
    
    func confirmedClearAll() {
        for item in arrayOfItems {
            if let itemname = item.name {
                listController?.removeItem(itemName: itemname)
            }
        }
        arrayOfItems.removeAll()
        self.reloadData()
    }
    @IBAction func clearAllButton() {
       let alert = UIAlertController(title: "Confirm Deletion", message: "Are you sure you want to clear all items from this shopping list?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
            self.confirmedClearAll()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func sortListButton() {
        sortList()
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
        }
        if let listid = self.currentID, let listname = listName {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.addListToDB(name: listname, id: listid)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupList()
        
        if listController != nil {
            listController?.databaseUpdateDelegate = self
        }

        self.navigationItem.rightBarButtonItem = self.getShareButton()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        addTableViewInsets()
    }
    func addTableViewInsets() {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 250, right: 0)
        self.tableView.contentInset = insets
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    var previousText:String?
    
    func scrollToItem(name:String) {
        if let index = arrayOfItems.index(where: {$0.name == name}) {
            self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
        }
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text?.isEmpty == false {
            textField.tag = 1
            previousText = textField.text
            scrollToItem(name: textField.text!)
        } else {
            if arrayOfItems.count > 1 {
                self.tableView.scrollToRow(at: IndexPath(row: arrayOfItems.count-1, section: 0), at: .middle, animated: true)
            }
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
                if let indexOfItem = arrayOfItems.index(where: {$0.name == previousItemName}) {
                    arrayOfItems[indexOfItem].name = textField.text
                }
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
        if arrayOfItems.index(where: {$0.name == name}) != nil {
            print("ERROR: Item already exists..")
            let alert = UIAlertController(title: "Duplicate item", message: "Item already exists in the list", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .destructive, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
        let newItem = Item(name: name, purchased: false)
        
        listController?.addItem(item: newItem)
        self.arrayOfItems.append(newItem)
        self.reloadData()
        }
    }
    
    func findAndRemoveItem(itemName:String) {
        guard let indexOfItem = arrayOfItems.index(where: {$0.name == itemName}) else {
            print("Error: Unable to find item to remove")
            return
        }
        
        arrayOfItems.remove(at: indexOfItem)
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
    @objc func handleDone() {
        self.view.endEditing(true)
        self.reloadData()
    }
    func getItemNameFromIndexpath(indexPath:IndexPath) -> String {
        let cell = self.tableView.cellForRow(at: indexPath) as! ItemTVC
        return cell.textField.text!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ItemTVC
        

        cell.delegate = self
        cell.textField.delegate = self
        cell.textField.inputAccessoryView = self.inputAccessoryViewOfTextField
        
        if (indexPath.row == arrayOfItems.count) {
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
        updateItem(itemName: itemName, tickInfo: tickInfo)
    }
    func updateItem(itemName:String, tickInfo:TickInfo) {
        let indexOfItem = arrayOfItems.index(where: {$0.name == itemName})

        if indexOfItem != nil {
            let itemReference = arrayOfItems[indexOfItem!] as Item
            
            if tickInfo == .Ticked {
                itemReference.purchased = true
            } else {
                itemReference.purchased = false
            }

            listController?.updateItemInfo(item: itemReference)
        }
        
    }
    
    
    // database update delegate
    func updateListWithEmptyData() {
        DispatchQueue.global(qos: .background).sync {
            self.arrayOfItems.removeAll()
        }
        self.reloadData()
    }
    func updateListWith(dataArray:[Item]) {
        //self.view.isUserInteractionEnabled = false
        //print("Beginning to update DB")

        DispatchQueue.global(qos: .userInteractive).async {
            self.arrayOfItems.removeAll()
            self.arrayOfItems = dataArray
            /*
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }*/
        }

        //self.view.isUserInteractionEnabled = true
        //print("Completed updating")
    }
    func reloadData() {
        self.tableView.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfItems.count + 1
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    @objc func shareButtonTapped(_ sender:UIBarButtonItem) {
        let shareOptionsController = UIAlertController(title: "Share", message: "Select a Sharing method", preferredStyle: .actionSheet)
        
        let copyClipboard = UIAlertAction(title: "Copy List ID to Clipboard", style: .default) { (action) in
            self.copyToClipboard()
        }
        let sendAsText = UIAlertAction(title: "Send list in text format", style: .default) { (action) in
            self.sendAsText()
        }
        let shareMessage = UIAlertAction(title: "Send as Message", style: .default) { (action) in
            self.sendAsMessage()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        
        shareOptionsController.addAction(copyClipboard)
        shareOptionsController.addAction(sendAsText)
        shareOptionsController.addAction(shareMessage)
        shareOptionsController.addAction(cancelAction)

        shareOptionsController.popoverPresentationController?.barButtonItem = sender
        self.present(shareOptionsController, animated: true, completion: nil)
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
        self.sendMessageWithID(listLink)
        
    }
    func sendAsText() {
        var stringOfItems = String.init()
        var count = 0
        for item in arrayOfItems {
            if count == 0 {
                stringOfItems.append(getStringOfItem(item: item))
            } else {
                stringOfItems.append("\n\(getStringOfItem(item: item))")
            }
            count = count + 1
        }
        self.sendMessageWithText(stringOfItems)
        
    }
    func getStringOfItem(item:Item) -> String {
        guard let itemname = item.name else {
            return ""
        }
        if item.purchased == true {
            return "(X) \(itemname)"
        } else {
            return "( ) \(itemname)"
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.handleDone()
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
