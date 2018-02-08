//
//  Extra classes.swift
//  Smart Home
//
//  Created by Deep Gajera on 20/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit

struct AttributedString {
    var name: String
    
    static func getUnderlinedString(name: String, OfSize size: CGFloat, with color: UIColor)
        -> NSMutableAttributedString {
            let attrs: [NSAttributedStringKey: Any] = [
                NSAttributedStringKey.font: UIFont(name: "Nunito-Regular", size: size)!,
                NSAttributedStringKey.foregroundColor: color,
                NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue
            ]
            
            return NSMutableAttributedString(string: name, attributes: attrs)
    }
}
