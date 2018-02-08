//
//  PassTextField.swift
//  Smart Home
//
//  Created by Deep Gajera on 19/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit

class PassTextField: UITextField {
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    private var showPasswordButton: UIButton!
    
    var passVisible: Bool = false {
        willSet {
            showPasswordButton.setImage(newValue ? #imageLiteral(resourceName: "pass_visible"):#imageLiteral(resourceName: "pass_hidden"), for: .normal)
            self.isSecureTextEntry = !newValue
        }
    }
    
    let padding = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 40)
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.size.width - 35, y: 13, width: 22, height: 22)
    }
    
    func setupRightView() {
        showPasswordButton = UIButton(frame: CGRect(x: 0, y: 0, width: 22, height: 22))
        showPasswordButton.setImage(#imageLiteral(resourceName: "pass_hidden"), for: .normal)
        showPasswordButton.contentMode = .scaleAspectFit
        showPasswordButton.addTarget(self, action: #selector(self.showPasswordPressed(_:)), for: .touchUpInside)
        self.rightView = showPasswordButton
        self.rightViewMode = .always
    }
    
    @objc
    private func showPasswordPressed(_ sender: UIButton) {
        if let count = self.text?.count, count > 0 {
            passVisible = !passVisible
        }
    }
}
