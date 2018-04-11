//
//  ViewController.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 23/06/2017.
//  Copyright © 2017 Dayan Yonnatan. All rights reserved.
//

import UIKit
import CoreData


class HomeViewController: UIViewController, ShoppingListSearchDelegate, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet var tableView:UITableView!
    var shoppingListVC:ShoppingListVC?
    var fetchedResultsController:NSFetchedResultsController<NSFetchRequestResult>?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkForDirectLink), name: NSNotification.Name.init("OpenLink"), object: nil)
        
        setupAndPerformFetch()
        self.navigationItem.rightBarButtonItem = createAddListButton()
        
    }
    func setupNavigationBar() {
        //self.navigationController?.navigationBar.barTintColor = UIColor.getCustomGreen()
        self.navigationController?.navigationBar.tintColor = UIColor.getCustomGreen()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.getCustomGreen()]
        
        
        //self.navigationController?.navigationBar.backgroundColor = UIColor.blue
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init("OpenLink"), object: nil)
    }
    func checkForDirectLink() {
        if let linkid = UserDefaults.standard.string(forKey: "DirectLink") {
            setupAndPerformFetch()
            self.openListWith(id: linkid)
            UserDefaults.standard.set(nil, forKey: "DirectLink")
        }
    }
    
   
    override func viewDidAppear(_ animated: Bool) {
        if shoppingListVC != nil {
            shoppingListVC = nil
        }
        setupAndPerformFetch()
        self.tableView.reloadData()
    }
    
    
    
    func setupAndPerformFetch() {
        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Lists")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateOpened", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: appDelegate.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: "Lists")
        do {
        try fetchedResultsController?.performFetch()
        } catch {
            print("Error fetching for fetchedResultsController")
        }
        
    }
    
    // Table View
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete List from Recents
            // FIXME: FINISH
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let fetchedObject = fetchedResultsController?.fetchedObjects![indexPath.row] as? Lists {
            guard let listid = fetchedObject.id else {
                return
            }
            self.openListWith(id: listid)
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    func getDateFormatter() -> DateFormatter {
        let dateFormat = DateFormatter.init()
        dateFormat.dateFormat = "HH:mm dd/MM/yyyy"
        return dateFormat
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recentCellID", for: indexPath)
        
        if fetchedResultsController?.fetchedObjects?.count == 0 {
            cell.textLabel?.text = "No recently opened lists. Tap \'+\' on top-right corner to create/open a list."
            cell.textLabel?.numberOfLines = 2
            cell.detailTextLabel?.text = nil
            cell.isUserInteractionEnabled = false
            return cell
        }
        
        if let fetchedObject = fetchedResultsController?.fetchedObjects![indexPath.row] as? Lists {
            cell.isUserInteractionEnabled = true
            cell.textLabel?.text = fetchedObject.name
            
            //if fetchedObject.dateOpened != nil {
            let fetchedDate = Date.init(timeIntervalSince1970: fetchedObject.dateOpened)
            cell.detailTextLabel?.text = "Last opened: " + getDateFormatter().string(from: fetchedDate)
           // }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Recents:"
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = (fetchedResultsController?.fetchedObjects?.count)!
        
        if rows == 0 {
            return 1
        } else {
            return rows
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    @objc func createOrOpenList(_ sender:UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Create a new list", style: .default, handler: { (action) in
            self.createNewList()
        }))
        alert.addAction(UIAlertAction(title: "Open an existing list by ID", style: .default, handler: { (action) in
            self.openExistingList()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = sender
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func createAddListButton() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createOrOpenList))
    }
    
    func createNewListWithName(name:String) {
        shoppingListVC = self.storyboard?.instantiateViewController(withIdentifier: "ShoppingListVC") as? ShoppingListVC
        shoppingListVC?.existingListID = nil
        shoppingListVC?.listName = name
        shoppingListVC?.listController = ListController()
        shoppingListVC?.listController?.createNewList(name: name)
        self.navigationController?.pushViewController(shoppingListVC!, animated: true)
    }
    func createNewList() {
        let alert = UIAlertController(title: "Name", message: "Give a name for your list", preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.autocapitalizationType = .sentences
        }
        alert.addAction(UIAlertAction(title: "Continue", style: .destructive, handler: { (action) in
            if alert.textFields?.last?.text != nil || alert.textFields?.last?.text != "" {
                self.createNewListWithName(name: (alert.textFields?.last?.text)!)
            }
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    func openExistingList() {
        let alertController = UIAlertController(title: "Open an existing List", message: "Enter list ID", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: nil)
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

    
    // To open an existing Shopping List
    func openListWith(id:String) {
        shoppingListVC = self.storyboard?.instantiateViewController(withIdentifier: "ShoppingListVC") as? ShoppingListVC
        shoppingListVC?.existingListID = id
        shoppingListVC?.listController = ListController()
        shoppingListVC?.listController?.connectToListWith(id: id)
        shoppingListVC?.listController?.listSearchDelegate = self
    }
    
    
    // Delegate method called when Shopping List with the same ID is found. Retrieve data and send to viewcontroller
    func foundListWith(dataArray: NSDictionary) {
        if dataArray.count <= 0 {
            print("No data.")
            return
        }
        print("Found list with array \(dataArray.count)!")
        
        for item in dataArray {
            let theitem = item.value as! NSDictionary
            let purchased = theitem["purchased"] as! Bool
            let itemName = item.key as! String
            
            //print("Item: \(itemName) purchased:\((purchased) ? "true" : "false")")
            let newItem = self.createNewItemWith(name: itemName, purchased: purchased)
            shoppingListVC?.arrayOfItems.append(newItem)
        }
        self.navigationController?.pushViewController(shoppingListVC!, animated: true)
    }
    // Found empty list
    func foundEmptyList() {
        self.navigationController?.pushViewController(shoppingListVC!, animated: true)
    }
    
    // Delegate method to set shopping list name
    func setListName(name:String) {
        shoppingListVC?.listName = name
    }
    
    
    // Delegate method called when Shopping List with matching ID is not found.
    func unableToFindList() {
        let alertController = UIAlertController(title: "Unable to find list", message: "Unable to find the list..\nMake sure you copy and paste the ID exactly as it is", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .destructive, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // To create a new Item object
    func createNewItemWith(name:String, purchased:Bool) -> Item {
        let item = Item(name: name, purchased: purchased)
        return item
    }
    
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

