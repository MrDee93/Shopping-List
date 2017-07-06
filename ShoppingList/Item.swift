//
//  Item.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 23/06/2017.
//  Copyright © 2017 Dayan Yonnatan. All rights reserved.
//

import Foundation

class Item {
    var name:String?
    var purchased:Bool? {
        didSet {
            self.dictionary?["purchased"] = self.purchased
        }
    }
    var dictionary:Dictionary<String, Any>?
    
    init(name:String, purchased:Bool) {
        self.dictionary = Dictionary()
        self.name = name
        self.purchased = purchased
        

        self.dictionary?["name"] = name
        self.dictionary?["purchased"] = purchased
    }
    
    func setItemFrom(dictionary:Dictionary<String, Any>) {
        if let thename = dictionary["name"] {
            self.name = (thename as! String)
        }
        if let isitempurchased = dictionary["purchased"] {
            self.purchased = (isitempurchased as! Bool)
        }
    }
    
    func getDictionaryData() -> Dictionary<String
        , Any> {
        return self.dictionary!
    }
}
