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

class SignInViewController: TextInputViewController {

    @IBOutlet weak var emailTextField: PaddedTextField!
    @IBOutlet weak var passTextField: PassTextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var transitToSignUpVCButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passTextField.delegate = self
        
        transitToSignUpVCButton.setAttributedTitle(AttributedString.getUnderlinedString(name: "Sign Up", OfSize: 14, with: Colors.attribtedString.color), for: UIControlState.normal)
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func performSignIn(_ sender: UIButton) {
        self.view.endEditing(true)
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.label.text = "Authorizing.."
        
        if let pass = self.passTextField.text, !pass.isEmpty,
            let email = self.emailTextField.text, !email.isEmpty {
            Auth.auth().signIn(withEmail: email, password: pass) { (user, err) in
                if err != nil, let errCode = AuthErrorCode(rawValue: err!._code) {
                    switch errCode {
                    case .networkError:
                        self.show(alert: .noInternetAccess)
                    case .invalidEmail:
                        self.show(alert: .invalidEmail)
                    case .wrongPassword, .userNotFound:
                        self.show(alert: .recordsDoesNotMatch)
                    case .operationNotAllowed:
                        self.show(alert: .toManyRequests)
                    default:
                        self.show(alert: .undefined)
                    }
                } else {
                    
                    let tabbarVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: StoryBoardIDs.tabbarVC.rawValue)
                    tabbarVC.heroModalAnimationType = .slide(direction: .left)
                    DispatchQueue.main.async {
                        self.hud.hide(animated: true)
                        self.hud.label.text = nil
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
    
    
    
    func addTargetToFields() {
        emailTextField.addTarget(self, action: #selector(self.editingChanged(_:)), for: .editingChanged)
        passTextField.addTarget(self, action: #selector(self.editingChanged(_:)), for: .editingChanged)
    }
    
    func show(alert: AuthAlertType) {
        hud.hide(animated: true)
        let alertView = UIAlertController(title: alert.title, message: alert.message, preferredStyle: UIAlertControllerStyle.alert)
        alertView.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alertView, animated: true, completion: nil)
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

extension SignInViewController {

    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        passTextField.passVisible = false
    }
    
    @objc func editingChanged(_ textField: UITextField) {
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

