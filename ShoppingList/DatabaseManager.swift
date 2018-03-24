//
//  DatabaseManager.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 23/03/2018.
//  Copyright © 2018 Dayan Yonnatan. All rights reserved.
//

import UIKit
import CoreData

class DatabaseManager {
    
    var appDelegate:AppDelegate!
    
    init(appdelegate:AppDelegate) {
        appDelegate = appdelegate
    }
    
    deinit {
        appDelegate = nil
    }
    
    func searchThenAddToDB(name:String, id:String) {
        self.searchListInDB(name: name, id: id)
    }
    func addNewListToDB(name:String, id:String) {
        appDelegate.persistentContainer.viewContext.perform({
            let newList:Lists = NSEntityDescription.insertNewObject(forEntityName: "Lists", into: self.appDelegate.persistentContainer.viewContext) as! Lists
            newList.name = name
            newList.id = id
            let dateopened = Date.init()
            newList.dateOpened = dateopened.timeIntervalSince1970
            self.appDelegate.saveContext()
        })
    }
    func searchListInDB(name:String, id:String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Lists")
        
        do {
            let objects = try appDelegate.persistentContainer.viewContext.fetch(fetchRequest) as! [Lists]
            for object in objects {
                if object.id == id {
                    let currentDate = Date.init()
                    object.dateOpened = currentDate.timeIntervalSince1970
                    appDelegate.saveContext()
                    print("EDITED DATE")
                    return
                }
            }
            self.addNewListToDB(name: name, id: id)
        }
        catch {
            print("Error searching DB")
            return
        }
    }
    
    
    func clearDatabase() {
        var fetchedData:[Lists]
        
        do {
            fetchedData = try appDelegate.persistentContainer.viewContext.fetch(Lists.fetchRequest())
            
        } catch {
            print("Error clearing Users from DB")
            return
        }
        
        
        for(_, element) in fetchedData.enumerated() {
            DispatchQueue.main.async {
                self.appDelegate.persistentContainer.viewContext.delete(element)
            }
        }
        DispatchQueue.main.async {
            self.appDelegate.saveContext()
        }
    }
    
    
}
