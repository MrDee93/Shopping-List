//
//  List.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 01/07/2017.
//  Copyright © 2017 Dayan Yonnatan. All rights reserved.
//

import Foundation


class List {
    
    var title:String?
    var members:[String]? = []
    var items:[Item]? = []
    
    init(title:String) {
        self.title = title
    }
    
    func addMember(id:String) {
        members?.append(id)
    }
    func addItem(item:Item) {
        items?.append(item)
    }
    
    
}
