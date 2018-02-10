//
//  BaseViewConteoller.swift
//  Smart Home
//
//  Created by Deep Gajera on 09/02/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import MBProgressHUD
import Firebase

class BaseViewController: UIViewController {
    
    @IBOutlet weak var messageView: MessageView!
    
    var hud: MBProgressHUD!
    
    var databaseConnection: Bool? = nil {
        didSet {
            if databaseConnection != oldValue {
                if let newVal = databaseConnection, newVal {
                    if messageView.isVisible {
                        let bgColor = UIColor(red: 0, green: 179/255.0, blue: 0, alpha: 1)
                        messageView.changeStillMessage("Back Online", color: bgColor, completionHandler: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
                                self.messageView.removeStillMessage()
                            })
                        })
                    }
                    if let doesExist = StatesManager.manager?.doesHandlerExist(forKeys: [.contAccess]), !doesExist {
                        StatesManager.manager?.startObservers(forKeys: [.contAccess])
                    }
                } else {
                    if !messageView.isVisible {
                        messageView.showStillMessage("No connection")
                        StatesManager.manager?.removeObservers(forKeys: Key.allKeys)
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        
        hud = MBProgressHUD()
        self.view.addSubview(hud)
        
        hud.isUserInteractionEnabled = false
        hud.label.text = "Loading.."
        
        let menuBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "menu"), landscapeImagePhone: nil, style: .done, target: self, action: #selector(menuBarButtonPressed(_:)))
        self.navigationItem.rightBarButtonItem = menuBarButtonItem
        
        self.isHeroEnabled = true
        
        super.viewDidLoad()
    }
    
    @objc func menuBarButtonPressed(_ sender: UIBarButtonItem ) {
        
        let logOutAction = UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
            let delegate = UIApplication.shared.delegate as! AppDelegate
            
            self.hud.show(animated: true)
            self.hud.label.text = "Logging out..."
            
            do {
                try Auth.auth().signOut()
                
                Fire.shared.stopMainObservers()
                StatesManager.manager = nil
                
                let signinViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: StoryBoardIDs.signInVC.rawValue)
                signinViewController.heroModalAnimationType = .push(direction: .right)
                delegate.window?.rootViewController = signinViewController
                self.hud.hide(animated: true)
                self.hero_unwindToRootViewController()
            } catch {
                print(error.localizedDescription)
                self.hud.hide(animated: true)
                
                return
            }
        })
        
        if !(databaseConnection ??  false) {
            logOutAction.isEnabled = false
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        self.showAlert(withActions: [logOutAction, cancelAction],
                       ofType: .actionSheet,
                       withMessage: (nil, nil),
                       complitionHandler: nil)
    }
}

extension UIViewController {
    func showAlert(withActions actions: [UIAlertAction], ofType type: UIAlertControllerStyle, withMessage message: (title: String?, message: String?), complitionHandler: (() -> ())? ) {
        let alertView = UIAlertController(title: message.title, message: message.message, preferredStyle: type)
        
        actions.forEach ({
            alertView.addAction($0)
        })
        
        self.present(alertView, animated: true, completion: complitionHandler)
    }
}








