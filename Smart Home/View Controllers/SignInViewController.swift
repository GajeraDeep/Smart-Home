//
//  SignInViewController.swift
//  Smart Home
//
//  Created by Deep Gajera on 18/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import Firebase
import MBProgressHUD

enum AuthAlertType {
    case noInternetAccess
    case recordsDoesNotMatch
    case invalidEmail
    case undefined
    case toManyRequests
    case emailUsed
    case weakPasword
    
    var title: String {
        switch self {
        case .noInternetAccess:
            return "No internt access"
        case .invalidEmail, .recordsDoesNotMatch, .emailUsed, .weakPasword:
            return "Please try again..."
        case .toManyRequests:
            return "Please try later..."
        case .undefined:
            return "Unknown error"
        }
    }
    
    var message: String {
        switch self {
        case .noInternetAccess:
            return "There seems to be no internet connection. Please check your connection and try again."
        case .invalidEmail:
            return "Email address seems invalid. Please check and try again."
        case .recordsDoesNotMatch:
            return "Username or password doesnot match our records. Please re-check and try again."
        case .emailUsed:
            return "Email already in used. Please try another one."
        case .weakPasword:
            return "Your password is not strong enough. Please enter stronger one."
        case .toManyRequests:
            return "To many requests from your device. Please try later."
        case .undefined:
            return "Unknown error has occured."
        }
    }
}

class SignInViewController: TextInputViewController {

    @IBOutlet weak var emailTextField: PaddedTextField!
    @IBOutlet weak var passTextField: PassTextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var transitToSignUpVCButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passTextField.delegate = self
        
        transitToSignUpVCButton.setAttributedTitle(self.getUnderlinedString(name: "Sign Up", OfSize: 14, with: Colors.attribtedString.color), for: UIControlState.normal)
        
        addTargetToFields()
        
        signInButton.layer.masksToBounds = false
        signInButton.layer.cornerRadius = 3
        signInButton.isEnabled = false
        signInButton.alpha = 0.50
        
        passTextField.setupRightView()
        
        self.isHeroEnabled = true
        
        whenLastTextFieldReturns = {
            self.performSignIn(self.signInButton)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func performSignIn(_ sender: UIButton) {
        self.view.endEditing(true)
        hud.label.text = "Authorizing.."
        hud.show(animated: true)
        
        if let pass = self.passTextField.text, !pass.isEmpty,
            let email = self.emailTextField.text, !email.isEmpty {
            Auth.auth().signIn(withEmail: email, password: pass) { (user, err) in
                if err != nil, let errCode = AuthErrorCode(rawValue: err!._code) {
                    switch errCode {
                    case .networkError:
                        self.showAuthenticationAlert(.noInternetAccess)
                    case .invalidEmail:
                        self.showAuthenticationAlert(.invalidEmail)
                    case .wrongPassword, .userNotFound:
                        self.showAuthenticationAlert(.recordsDoesNotMatch)
                    case .operationNotAllowed:
                        self.showAuthenticationAlert(.toManyRequests)
                    default:
                        self.showAuthenticationAlert(.undefined)
                    }
                } else {
                    
                    let tabbarVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: StoryBoardIDs.tabbarVC.rawValue)
                    tabbarVC.heroModalAnimationType = .slide(direction: .left)
                    DispatchQueue.main.async {
                        self.hud.hide(animated: true)
                    }
                    self.hero_replaceViewController(with: tabbarVC)
                }
            }
        }
    }
    
    @IBAction func signUpPressed(_ sender: UIButton) {
        let createAccountVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: StoryBoardIDs.createAccountVC.rawValue)
        createAccountVC.heroModalAnimationType = .autoReverse(presenting: .fade)
        self.hero_replaceViewController(with: createAccountVC)
    }
    
    override func editingChanged() {
        guard let email = emailTextField.text, !email.isEmpty,
            let pass = passTextField.text, !pass.isEmpty else {
                signInButton.isEnabled = false
                signInButton.alpha = 0.50
                return
        }
        signInButton.isEnabled = true
        signInButton.alpha = 1
    }
}

extension SignInViewController {

    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        passTextField.passVisible = false
    }
}

