//
//  ItemTVC.swift
//  ShoppingList
//
//  Created by Dayan Yonnatan on 27/06/2017.
//  Copyright © 2017 Dayan Yonnatan. All rights reserved.
//

import UIKit

enum TickInfo {
    case Ticked
    case Unticked
}

protocol UpdateTableDelegate:class {
    func changeTickInfo(tickInfo:TickInfo,_ itemName:String)
}

class ItemTVC: UITableViewCell {
    var item:Item?
    
    @IBOutlet var textField:UITextField!
    @IBOutlet var checkBoxButton:UIButton!
    
    weak var delegate:UpdateTableDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.checkBoxButton.isHidden = false
        self.textField.isHidden = false

        textField.returnKeyType = .done
    }
    
    
    
    @IBAction func itemCheckedOff(_ sender:UIButton) {
        if (textField.text?.isEmpty)! {
            return
        }
        
        self.endEditing(true)
        if sender.tag == 0 {
            self.setTicked()
            delegate?.changeTickInfo(tickInfo: .Ticked, self.textField.text!)
        } else {
            self.setUnticked()
            delegate?.changeTickInfo(tickInfo: .Unticked, self.textField.text!)
        }
    }
    func setTicked() {
        self.checkBoxButton.setImage(UIImage(named:"ticked"), for: .normal)
        self.checkBoxButton.tag = 1
    }
    func setUnticked() {
        self.checkBoxButton.setImage(UIImage(named:"unticked"), for: .normal)
        self.checkBoxButton.tag = 0
    }
    
   
    override func prepareForReuse() {
        setUnticked()
        self.textField.text = nil
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
