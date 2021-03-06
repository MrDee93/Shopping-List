//
//  ViewController.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 23/06/2017.
//  Copyright © 2017 Dayan Yonnatan. All rights reserved.
//

import UIKit
import CoreData


final class HomeViewController: UIViewController, ShoppingListSearchDelegate, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    var refreshControl:UIRefreshControl!
    
    @IBOutlet var tableView:UITableView!
    var shoppingListVC:ShoppingListVC?
    private var fetchedResultsController:NSFetchedResultsController<NSFetchRequestResult>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        refreshControl = UIRefreshControl()
        self.tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(refreshView), for: UIControlEvents.valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkForDirectLink), name: NSNotification.Name.init("OpenLink"), object: nil)
        
        
        setupAndPerformFetch()
        self.navigationItem.rightBarButtonItem = createAddListButton()
    }
    
    
    @objc func refreshView() {
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    func setupNavigationBar() {
        self.navigationController?.navigationBar.tintColor = UIColor.getCustomGreen()
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.getCustomGreen()]
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init("OpenLink"), object: nil)
    }
    @objc func checkForDirectLink() {
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
        fetchedResultsController?.delegate = self
        do {
        try fetchedResultsController?.performFetch()
        } catch {
            print("Error fetching for fetchedResultsController")
        }
    }
    func performFetch() {
        do {
            try fetchedResultsController?.performFetch()
        }
        catch {
            print("ERROR")
        }
    }
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
            case .delete:
                if (controller.fetchedObjects?.count)! < 1 {
                    self.tableView.reloadData()
                } else {
                    self.tableView.deleteRows(at: [indexPath!], with: .automatic)
                }
                break
            case .insert:
                if (controller.fetchedObjects?.count)! == 1 {
                    self.tableView.reloadData()
                } else {
                    self.tableView.insertRows(at: [newIndexPath!], with: .automatic)
                }
                break
            case .move:
                break
            case .update:
                break
        }
    }
    
    // Table View

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let object = fetchedResultsController?.object(at: indexPath)
            fetchedResultsController?.managedObjectContext.delete(object as! NSManagedObject)
            do {
                try fetchedResultsController?.managedObjectContext.save()
            }
            catch {
                print("Error")
            }
            
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
            return
        }
        //print("Found list with array \(dataArray.count)!")
        
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

