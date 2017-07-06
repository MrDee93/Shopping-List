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
    func unableToFindList()
}

protocol DatabaseUpdateDelegate:class {
    func updateListWith(dataArray:[Item]) // finish off creating this update system.. worried that it might crash when I clear the 'arrayOfItems' array so figure out a way to quickly replace it before the tableview realises it or just find a way to stop it crashing.. if it does
}


class ListController {
    var firstRun:Bool?
    var firebaseRef:DatabaseReference!
    var listID:String?
    let user:String!
    
    // list
    var listRef:DatabaseReference?
    weak var listSearchDelegate:ShoppingListSearchDelegate?
    
    weak var databaseUpdateDelegate:DatabaseUpdateDelegate?
    
    init(user:String) {
        self.firebaseRef = Database.database().reference().child("lists")
        self.user = user
    }
    func getListID() -> String {
        return removeDashFromString(self.listID!)
    }
    
    func createNewList() {
        listRef = firebaseRef.childByAutoId()
        self.listID = listRef?.key
        //var arrayOfUsers = [String]()
        //arrayOfUsers.append(self.user)
        
        listRef?.child("founder").setValue(user!)
        
    }
    func removeDashFromString(_ inputstring:String) -> String {
        //let dash = inputstring.substring(to: inputstring.index(after: inputstring.startIndex))
        
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
        if firstRun == false {
            print("NEW UPDATE FOUND!!!!!")
            //databaseUpdateDelegate?.updateListWith(dataArray: downloadData())
            downloadData()
        } else {
            firstRun = false
        }
    }
    
    func downloadData(){ //-> [Item] {
        var itemArray = [Item]()
        
        listRef?.observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot.value)
        })
        
        
    }
    func connectToListWith(id:String) {
        firstRun = true
        let listID = cleanUpString(id)
        listRef = firebaseRef.child(listID)
        
        firebaseRef.observeSingleEvent(of: .value, with: { (snapshot) in

            //firebaseRef.observe(.value, with: { (snapshot) in
            if let value = snapshot.value as? NSDictionary {
            
            for item in value {
                //print(item)
                let listid = item.key as! NSString
                //print("\(listid) vs \(listID) == ", listid.compare(listID) == ComparisonResult.orderedAscending)
                if listid.compare(listID) == ComparisonResult.orderedSame {
                    self.foundListIDWith(data: item.value as! NSDictionary)
                    self.listenForUpdates()
                    return
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
            print("Added item!")
        }
    }
    
    func updateItemInfo(item:Item) {
        if listRef != nil {
            
            listRef?.child("items").child(item.name!).setValue(item.getDictionaryData())
            print("Changed \(item.name!) to \(item.purchased! ? "purchased" : "not purchased")")
        } else {
            print("List ref is nil")
        }
    }
    
    
    
    
    
    
    
    
}
