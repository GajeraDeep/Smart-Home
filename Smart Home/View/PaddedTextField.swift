//
//  BigUITextField.swift
//  Smart Home
//
//  Created by Deep Gajera on 18/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit

class PaddedTextField: UITextField {

    @IBInspectable var padding: CGFloat = 0
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
//    override func draw(_ rect: CGRect) {
//    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, edgeInsets())
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, edgeInsets())
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, edgeInsets())
    }
    
    func edgeInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }
}
