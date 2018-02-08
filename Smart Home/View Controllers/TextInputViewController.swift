//
//  TextInputViewController.swift
//  Smart Home
//
//  Created by Deep Gajera on 01/02/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import MBProgressHUD

class TextInputViewController: UIViewController {

    var tapGesture: UITapGestureRecognizer!
    var whenLastTextFieldReturns: (() -> ())!
    
    var hud: MBProgressHUD!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addDismissKeyboardGesture()
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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
