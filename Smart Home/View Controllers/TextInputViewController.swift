//
//  TextInputViewController.swift
//  Smart Home
//
//  Created by Deep Gajera on 01/02/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import MBProgressHUD
import Hero

class TextInputViewController: UIViewController {

    @IBOutlet weak var textFieldsStack: UIStackView!
    
    var tapGesture: UITapGestureRecognizer!
    var whenLastTextFieldReturns: (() -> ())!
    
    var hud: MBProgressHUD!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        hud = MBProgressHUD()
        hud.isUserInteractionEnabled = false
        
        view.addSubview(hud)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addDismissKeyboardGesture()
    }

    func addDismissKeyboardGesture() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.isEnabled = false
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard(_ tapGesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func addTargetToFields() {
        self.textFieldsStack.subviews.forEach { (view) in
            if let textField = view as? UITextField {
                textField.addTarget(self, action: #selector(self.editingChanged), for: .editingChanged)
            }
        }
    }
    
    @objc func editingChanged() {
    }
    
    func showAuthenticationAlert(_ alert: AuthAlertType) {
        hud.hide(animated: true)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        
        self.showAlert(withActions: [okAction], ofType: .alert, withMessage: (alert.title, alert.message), complitionHandler: nil)
    }
    
    func getUnderlinedString(name: String, OfSize size: CGFloat, with color: UIColor)
        -> NSMutableAttributedString {
            let attrs: [NSAttributedStringKey: Any] = [
                NSAttributedStringKey.font: UIFont(name: "Nunito-Regular", size: size)!,
                NSAttributedStringKey.foregroundColor: color,
                NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue
            ]
            
            return NSMutableAttributedString(string: name, attributes: attrs)
    }
}

extension TextInputViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        tapGesture.isEnabled = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        tapGesture.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextTextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            whenLastTextFieldReturns()
        }
        
        return false
    }
}
