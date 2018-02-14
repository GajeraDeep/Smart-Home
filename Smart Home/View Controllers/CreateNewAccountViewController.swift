//
//  CreateNewAccountViewController.swift
//  Smart Home
//
//  Created by Deep Gajera on 18/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import Firebase
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
        transitToSignInVCButton.setAttributedTitle(self.getUnderlinedString(name: "Sign In", OfSize: 14, with: Colors.attribtedString.color), for: .normal)
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func signupPressed(_ sender: UIButton) {
        self.view.endEditing(true)
        
        hud.label.text = "Creating Acount.."
        hud.show(animated: true)
        
        if let userName = userNameTextField.text, !userName.isEmpty,
            let email = emailTextField.text, !email.isEmpty,
            let pass = passTextField.text, !pass.isEmpty {
            Auth.auth().createUser(withEmail: email, password: pass, completion: { (user, err) in
                if err != nil, let errCode = AuthErrorCode(rawValue: err!._code) {
                    switch errCode {
                    case .networkError:
                        self.showAuthenticationAlert(.noInternetAccess)
                    case .invalidEmail:
                        self.showAuthenticationAlert(.invalidEmail)
                    case .emailAlreadyInUse:
                        self.showAuthenticationAlert(.emailUsed)
                    case .operationNotAllowed:
                        self.showAuthenticationAlert(.toManyRequests)
                    case .weakPassword:
                        self.showAuthenticationAlert(.weakPasword)
                    default:
                        self.showAuthenticationAlert(.undefined)
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
    
    override func editingChanged() {
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

extension CreateNewAccountViewController {
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        passTextField.passVisible = false
    }
}


