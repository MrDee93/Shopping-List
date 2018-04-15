//
//  TextFieldAdjustingSize.swift
//  Shopping List
//
//  Created by Dayan Yonnatan on 15/04/2018.
//  Copyright © 2018 Dayan Yonnatan. All rights reserved.
//

import UIKit

extension UITextField {
    internal func resizeText() {
        if let text = self.text{
            self.font = UIFont.systemFont(ofSize: 14)
            let textString = text as NSString
            var widthOfText = textString.size(withAttributes: [kCTFontAttributeName as NSAttributedStringKey as NSAttributedStringKey : self.font!]).width
            var widthOfFrame = self.frame.size.width
            // decrease font size until it fits
            while widthOfFrame - 5 < widthOfText {
                let fontSize = self.font!.pointSize
                self.font = self.font?.withSize(fontSize - 0.5)
                widthOfText = textString.size(withAttributes: [kCTFontAttributeName as NSAttributedStringKey : self.font!]).width
                widthOfFrame = self.frame.size.width
            }
        }
    }
}
