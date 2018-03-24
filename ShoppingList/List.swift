//
//  List.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 01/07/2017.
//  Copyright © 2017 Dayan Yonnatan. All rights reserved.
//

import Foundation


class List { //}: Codable {
    
    var title:String?
    //var members:[String]? = []
    var items:[Item]? = []
    
    init(title:String) {
        self.title = title
    }
    /*
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys)
        values.
        
    }
    func encode(to encoder: Encoder) throws {
        
    }*/
    
    
    func addItem(item:Item) {
        items?.append(item)
    }
    
    /*
    enum CodingKeys: NSDictionary, String, CodingKey {
        case title = "title"
        case items = "
    }*/
    
    
}
