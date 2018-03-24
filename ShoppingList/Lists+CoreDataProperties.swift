//
//  Lists+CoreDataProperties.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 23/03/2018.
//  Copyright © 2018 Dayan Yonnatan. All rights reserved.
//
//

import Foundation
import CoreData


extension Lists {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Lists> {
        return NSFetchRequest<Lists>(entityName: "Lists")
    }

    @NSManaged public var id: String?
    @NSManaged public var dateOpened: Double
    @NSManaged public var name: String?

}
