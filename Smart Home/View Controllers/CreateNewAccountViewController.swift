//
//  CreateNewAccountViewController.swift
//  Smart Home
//
//  Created by Deep Gajera on 18/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import Firebase
import Hero
import MBProgressHUD

class CreateNewAccountViewController: TextInputViewController {

    
    @IBOutlet weak var emailTextField: PaddedTextField!
    @IBOutlet weak var userNameTextField: PaddedTextField!
    @IBOutlet weak var passTextField: PassTextField!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var transitToSignInVCButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set delegate to self
        userNameTextField.delegate = self
        emailTextField.delegate = self
        passTextField.delegate = self
        
        addTargetToFields()
        
        // set underline string for button
        transitToSignInVCButton.setAttributedTitle(AttributedString.getUnderlinedString(name: "Sign In", OfSize: 14, with: Colors.attribtedString.color), for: .normal)
        
        signupButton.layer.cornerRadius = 3
        signupButton.layer.masksToBounds = false
        signupButton.alpha = 0.50
        signupButton.isEnabled = false
        
        passTextField.setupRightView()
        
        self.isHeroEnabled = true
        
        whenLastTextFieldReturns = {
            self.signupPressed(self.signupButton)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func signupPressed(_ sender: UIButton) {
        self.view.endEditing(true)
        
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.label.text = "Creating Acount.."
        
        if let userName = userNameTextField.text, !userName.isEmpty,
            let email = emailTextField.text, !email.isEmpty,
            let pass = passTextField.text, !pass.isEmpty {
            Auth.auth().createUser(withEmail: email, password: pass, completion: { (user, err) in
                if err != nil, let errCode = AuthErrorCode(rawValue: err!._code) {
                    switch errCode {
                    case .networkError:
                        self.show(alert: .noInternetAccess)
                    case .invalidEmail:
                        self.show(alert: .invalidEmail)
                    case .emailAlreadyInUse:
                        self.show(alert: .emailUsed)
                    case .operationNotAllowed:
                        self.show(alert: .toManyRequests)
                    case .weakPassword:
                        self.show(alert: .weakPasword)
                    default:
                        self.show(alert: .undefined)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.hud.hide(animated: true)
                        self.hud.label.text = nil
                    }
                    
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.displayName = userName
                    
                    changeRequest?.commitChanges(completion: { (error) in
                        if let e = error {
                            print(e.localizedDescription)
                        }
                    })
                    
                    let getControllerIDVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: StoryBoardIDs.inputControler_idVC.rawValue)
                    getControllerIDVC.heroModalAnimationType = .slide(direction: .left)

                    self.hero_replaceViewController(with: getControllerIDVC)
                }
            })
        }
    }
    
    @IBAction func signInPressed(_ sender: UIButton) {
        let signInVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: StoryBoardIDs.signInVC.rawValue)
        signInVC.heroModalAnimationType = .fade
        self.hero_replaceViewController(with: signInVC)
    }

    func show(alert: AuthAlertType) {
        hud.hide(animated: true)
        
        let alertView = UIAlertController(title: alert.title, message: alert.message, preferredStyle: UIAlertControllerStyle.alert)
        alertView.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alertView, animated: true, completion: nil)
    }
    
    func addTargetToFields() {
        userNameTextField.addTarget(self, action: #selector(self.editingChanged(_:)), for: .editingChanged)
        emailTextField.addTarget(self, action: #selector(self.editingChanged(_:)), for: .editingChanged)
        passTextField.addTarget(self, action: #selector(self.editingChanged(_:)), for: .editingChanged)
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

extension CreateNewAccountViewController {
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        passTextField.passVisible = false
    }
    
    @objc func editingChanged(_ textField: UITextField) {
        guard let userName = userNameTextField.text, !userName.isEmpty,
            let email = emailTextField.text, !email.isEmpty,
            let pass = passTextField.text, !pass.isEmpty else {
                signupButton.isEnabled = false
                signupButton.alpha = 0.50
                return
        }
        signupButton.isEnabled = true
        signupButton.alpha = 1
    }
}


