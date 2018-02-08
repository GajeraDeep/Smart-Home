//
//  InputControllerIDViewController.swift
//  Smart Home
//
//  Created by Deep Gajera on 20/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import Firebase
import MBProgressHUD

class GetControllerIDViewController: TextInputViewController {
    
    @IBOutlet weak var doneBarItem: UIBarButtonItem!
    @IBOutlet var idTextFieldCollection: [UITextField]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        idTextFieldCollection.forEach { (textField) in
            textField.setShadowWithHeight(6, shadowRadius: 10, opacity: 0.15)
            textField.addTarget(self, action: #selector(self.editingChanged(_:)), for: .editingChanged)
            addNextButtonOnKeyboardFor(textField)
            textField.delegate = self
        }
        
        doneBarItem.isEnabled = false
        doneBarItem.image = #imageLiteral(resourceName: "done_bar_but_dimmed")
        doneBarItem.action = #selector(processControllerID)
        
        whenLastTextFieldReturns = {
            self.processControllerID()
        }
        
        if let firstResponder = self.view.viewWithTag(1) as? UITextField {
            firstResponder.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Are you sure?", message: "You are trying to stop account creation in middle, are you sure?", preferredStyle: .alert)
        
        let yes = UIAlertAction(title: "Yes", style: .destructive) { (action) in
            Auth.auth().currentUser?.delete(completion: { (error) in
                if error != nil {
                    print(error?.localizedDescription ?? "Error deleting user account")
                }
            })
            
            let createAccountVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: StoryBoardIDs.createAccountVC.rawValue)
            createAccountVC.heroModalAnimationType = .uncover(direction: .down)
            self.hero_replaceViewController(with: createAccountVC)
        }
        
        let no = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alert.addAction(yes)
        alert.addAction(no)
        
        self.present(alert, animated: true, completion: nil)
    }

    func addNextButtonOnKeyboardFor(_ textField: UITextField) {
        let toolBar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolBar.barStyle = .default
        let flexSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let next: UIBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "next_bar_but_dimmed").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.shiftToNextTextfield))
        let done: UIBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "done_bar_but_dimmed").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.processControllerID))
        done.isEnabled = false
        next.isEnabled = false
        
        textField.inputAccessoryView = {
            if textField.tag != 3 {
                toolBar.items = [flexSpace, next]
                toolBar.sizeToFit()
                return toolBar
            } else {
                toolBar.items = [flexSpace, done]
                toolBar.sizeToFit()
                return toolBar
            }
        }()
    }
    
    func setBarButtonVisiblityTo(_ visible: Bool,for textField: UITextField, with tag: Int) {
        if let toolbar = textField.inputAccessoryView as? UIToolbar {
            let barButton = toolbar.items?.last
            barButton?.image = tag < 3 ? (visible ? #imageLiteral(resourceName: "next_bar_but"):#imageLiteral(resourceName: "next_bar_but_dimmed")) : (visible ? #imageLiteral(resourceName: "done_bar_but"):#imageLiteral(resourceName: "done_bar_but_dimmed"))
            barButton?.isEnabled = visible
            
            if tag == 3 {
                doneBarItem.image = visible ? #imageLiteral(resourceName: "done_bar_but"):#imageLiteral(resourceName: "done_bar_but_dimmed")
                doneBarItem.isEnabled = visible
            }
        }
    }
    
    @objc func editingChanged(_ textField: UITextField) {
        if textField.tag < 3 {
            if let text = textField.text, text.count < 4 {
                setBarButtonVisiblityTo(false, for: textField, with: 1)
            } else {
                setBarButtonVisiblityTo(true, for: textField, with: 1)
            }
        }
        else {
            for field in idTextFieldCollection {
                if let text = field.text, text.isEmpty || text.count < 4 {
                    setBarButtonVisiblityTo(false, for: textField, with: 3)
                    return
                }
            }
            setBarButtonVisiblityTo(true, for: textField, with: 3)
        }
    }
    
    @objc func shiftToNextTextfield() {
        for textField in idTextFieldCollection {
            if textField.isFirstResponder {
                if let nextTextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
                    nextTextField.becomeFirstResponder()
                    return
                }
            }
        }
    }
    
    func presentTabbarVC() {
        hud.hide(animated: true)
        let tabbarVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: StoryBoardIDs.tabbarVC.rawValue)
        tabbarVC.heroModalAnimationType = .slide(direction: .left)
        self.hero_replaceViewController(with: tabbarVC)
    }
    
    @objc func processControllerID() {
        self.view.endEditing(true)
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.label.text = "Verifying.."

        let cid = self.combinedControllerID()
        
        let cidPath = "C_list/\(cid)"

        Fire.shared.doesDataExist(at: cidPath) { (cidExist, data) in
            if cidExist {
                var userData: [String: Any] = [:]
                userData["cid"] = cid
                
                let headPath = "heads/\(cid)"
                
                Fire.shared.doesDataExist(at: headPath, compltionHandler: { (exist, data) in
                    
                    if !exist {
                        self.doesUserWantToBeHead(complitionHandler: { (isTrue) in
                            self.hud.show(animated: true)
                            self.hud.label.text = "Finalizing.."
                            if isTrue {
                                userData["isHead"] = true
                            }
                            
                            if let user = Auth.auth().currentUser {
                                Fire.shared.newUser(user, withData: userData, complitionHandler: { (success) in
                                    if success {
                                        self.presentTabbarVC()
                                    }
                                })
                            }
                        })
                    } else {
                        self.hud.show(animated: true)
                        if let user = Auth.auth().currentUser {
                            Fire.shared.newUser(user, withData: userData, complitionHandler: { (success) in
                                if success {
                                    self.presentTabbarVC()
                                }
                            })
                        }
                    }
                })
            }
            else {
                self.hud.hide(animated: true)
                let alert = UIAlertController(title: "ID dosn't match..", message: "ID you entered doesnot match our database please re-check and try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func doesUserWantToBeHead(complitionHandler: @escaping (Bool) -> ()) {

        let alert = UIAlertController(title: "No Head", message: "No head is present for your controller ID, do you want to be head?", preferredStyle: .alert)
    
        let ok = UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            complitionHandler(true)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let wait = UIAlertAction(title: "Wait", style: .destructive) { _ in
                complitionHandler(false)
            }
            
            let becomeHead = UIAlertAction(title: "Become head", style: .default) {
                _ in
                complitionHandler(true)
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            actionSheet.addAction(becomeHead)
            actionSheet.addAction(wait)
            actionSheet.addAction(cancel)
            
            self.hud.hide(animated: true)
            self.present(actionSheet, animated: true, completion: nil)
            
        })
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.hud.hide(animated: true)
        self.present(alert, animated: true, completion: nil)
    }
    
    func combinedControllerID() -> String {
        let sortedTFCollection = idTextFieldCollection.sorted { $0.tag < $1.tag }
        return sortedTFCollection.map({$0.text!}).joined(separator: "-")
    }
    
}

extension GetControllerIDViewController {
    override func textFieldDidBeginEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        if textField.tag == 3 {
            editingChanged(textField)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let previousText = textField.text {
            let str = previousText + string
            if str.count <= 4 {
                return true
            } else {
                textField.text = String(str[str.startIndex ... str.index(str.startIndex, offsetBy: 3)])
                return false
            }
        }
        return false
    }
}
