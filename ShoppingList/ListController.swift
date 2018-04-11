//
//  TableController.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 04/07/2017.
//  Copyright © 2017 Dayan Yonnatan. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Firebase

protocol ShoppingListSearchDelegate:class {
    func foundListWith(dataArray:NSDictionary)
    func foundEmptyList()
    func unableToFindList()
    func setListName(name:String)
}

protocol DatabaseUpdateDelegate:class {
    func updateListWith(dataArray:[Item]) // finish off creating this update system.. worried that it might crash when I clear the 'arrayOfItems' array so figure out a way to quickly replace it before the tableview realises it or just find a way to stop it crashing.. if it does
    func reloadData()
}
enum RunningStatus {
    case Active
    case Inactive
}

class ListController {
    var runningStatus:RunningStatus = .Inactive
    var firstRun:Bool?
    var firebaseRef:DatabaseReference!
    var listID:String?
    //let user:String!
    
    // list
    var listRef:DatabaseReference?
    weak var listSearchDelegate:ShoppingListSearchDelegate?
    
    weak var databaseUpdateDelegate:DatabaseUpdateDelegate?
    
    
    init() {
        self.firebaseRef = Database.database().reference().child("lists")
    }
    func getListID() -> String {
        return removeDashFromString(self.listID!)
    }
    
    func createNewList(name:String) {
        listRef = firebaseRef.childByAutoId()
        self.listID = listRef?.key
        listRef?.child("name").setValue(name)

        listenForUpdates()
        
    }
    
    
    func removeDashFromString(_ inputstring:String) -> String {
        return inputstring.substring(from: inputstring.index(after: inputstring.startIndex))

    }
    func cleanUpString(_ inputstring:String) -> String {
        let newString = inputstring.replacingOccurrences(of: " ", with: "")
        
        let firstChar = newString.substring(to: inputstring.index(after: inputstring.startIndex))
       
        if firstChar == "-" {
            return newString
        } else {
            return "-" + newString
        }
    }
    func listenForUpdates() {
        firebaseRef.observe(.value, with: { (snapshot) in
            self.valueChanged()
        })
    }
    
    func valueChanged() {
        if firstRun == false && runningStatus == .Inactive {
            runningStatus = .Active
            downloadData()
        } else {
            firstRun = false
        }
    }
    
    func downloadData(){ //-> [Item] {
        var itemArray = [Item]()
        
        listRef?.child("items").observeSingleEvent(of: .value, with: { (snapshot) in
            guard let fetchedItems = snapshot.value as? NSDictionary else {
                self.runningStatus = .Inactive
                return
            }
            
            
            for item in fetchedItems {
                let itemDict = item.value as! NSDictionary
                print("Item: \(itemDict["name"] as! String) == \(itemDict["purchased"] as! Bool)")
                
                itemArray.append(Item(name: itemDict["name"] as! String, purchased: itemDict["purchased"] as! Bool))
            }
            
            if itemArray.count >= 1 {
                
                self.sendNewData(data: itemArray)
            }
            self.runningStatus = .Inactive
            //print("\(fetchedItem["name"] as? String) - \(fetchedItem["purchased"] as? Bool)")
        })
    }
    func sendNewData(data:[Item]) {
        databaseUpdateDelegate?.updateListWith(dataArray: data)
    }
    
    
    func connectToListWith(id:String) {
        firstRun = true
        let listID = cleanUpString(id)
        listRef = firebaseRef.child(listID)
        
        firebaseRef.observeSingleEvent(of: .value, with: { (snapshot) in

            if let value = snapshot.value as? NSDictionary {
            
            for item in value {
                let listid = item.key as! NSString
                if let listName = item.value as? NSDictionary {
                    if let name = listName.value(forKey: "name") as? String {
                    self.listSearchDelegate?.setListName(name: name)
                    }
                }
                if listid.compare(listID) == ComparisonResult.orderedSame {
                    print("Found list.. trying to open")
                    if let itemvalue = item.value as? NSDictionary {
                        if itemvalue.count <= 1 {
                            print("No data.. opening either way")
                            self.listSearchDelegate?.foundEmptyList()
                            return
                        } else {
                            self.foundListIDWith(data: itemvalue)
                            self.listenForUpdates()
                            return
                        }
                    }
                }
            }
                self.unableToFindList()
        } else {
                self.unableToFindList()
            }
        })
        
    }
    func unableToFindList() {
        if listSearchDelegate != nil {
            listSearchDelegate?.unableToFindList()
        }
    }
    func foundListIDWith(data:NSDictionary) {
        if listSearchDelegate != nil {
            let itemsInArray = data
            
            for item in itemsInArray {
                if (item.key as! String) == "items" {
                    listSearchDelegate?.foundListWith(dataArray: item.value as! NSDictionary)
                }
            }

        }
    }
    func addItem(item:Item) {
        if listRef != nil {

            listRef?.child("items").child(item.name!).setValue(item.getDictionaryData())
            print("Added item: \(item.name!)!")
        }
    }
    
    
    func updateItemInfo(item:Item) {
        if listRef != nil {
            listRef?.child("items").child(item.name!).setValue(item.getDictionaryData())
        }
    }
    
    func updateItemNameFor(oldItemName:String, newItemName:String) {
        if listRef != nil {
            getItemDetails(itemName: oldItemName, newItemName: newItemName)
        }
    }
    func getItemDetails(itemName:String, newItemName:String) {
        listRef?.child("items").child(itemName).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let itemDict = snapshot.value as? NSDictionary {
                
            print("Item: \(itemDict["name"] as! String) == \(itemDict["purchased"] as! Bool)")
            
            let item = Item(name: newItemName, purchased: itemDict["purchased"] as! Bool)
            self.removeAndReplaceItemWith(item: item, oldItemName: itemName)
            }
        })
    }
    func removeAndReplaceItemWith(item:Item, oldItemName:String) {
        if listRef != nil {
            listRef?.child("items").child(oldItemName).removeValue()
            listRef?.child("items").child(item.name!).setValue(item.getDictionaryData())
            print("Dispatch async")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { 
                self.databaseUpdateDelegate?.reloadData()
                print("Reload")
            })
        }
    }
    
    func removeItem(itemName:String) {
        if listRef != nil {
            listRef?.child("items").child(itemName).removeValue()
        }
    }
    
    
    
    
    
}
