//
//  ControllerViewController.swift
//  Smart Home
//
//  Created by Deep Gajera on 17/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import MBProgressHUD
import LocalAuthentication

class ControllerViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var userListProvider: UserList!
    
    override var databaseConnection: Bool? {
        didSet {
            super.databaseConnection = databaseConnection
            if databaseConnection != oldValue {
                databaseConnection! ? userListProvider.startObserver() : userListProvider.removeObserver()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hud.show(animated: true)
        
        userListProvider = UserList(CID: Fire.shared.myCID!, tableView: self.tableView)
        userListProvider.delegate = self
        
        self.tableView.allowsSelection = false
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        self.tableView.delegate = userListProvider
        self.tableView.dataSource = userListProvider
        
        self.messageView.initMessage()
        
        let connHandler: (Bool) -> () = { state in
            if state == Reachability.isConnectedToNetwork() {
                self.databaseConnection = state
            }
        }
        Fire.shared.connChangeshandlers.append(connHandler)
        
        if let isHead = StatesManager.manager?.isUserHead, isHead {
            setEditBarButtonItem()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        userListProvider.startObserver()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        userListProvider.removeObserver()
    }
    
    func setEditBarButtonItem() {
        let editButItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editBarItemPressed(_:)))
        self.navigationItem.leftBarButtonItem = editButItem
    }
    
    @objc func editBarItemPressed(_ sender: UIBarButtonItem) {
        if messageView.isVisible {
            messageView.flashStillMessage()
        } else {
            if self.userListProvider.enableEditing {
                hud.label.text = "Syncing.."
                hud.show(animated: true)
                
                self.userListProvider.enableEditing = false
                self.navigationItem.leftBarButtonItem?.title = "Edit"
            } else {
                authenticateUser()
            }
        }
    }
    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Please identify yourself!"
            
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: reason) {
                [unowned self] success, error in
                DispatchQueue.main.async {
                    guard success else {
                        return
                    }
                    self.hud.label.text = "Fetching.."
                    self.hud.show(animated: true)
                    
                    self.userListProvider.enableEditing = true
                    self.navigationItem.leftBarButtonItem?.title = "Done"
                }
            }
        } else {
            if error?.code == LAError.biometryLockout.rawValue {

                let okAction = UIAlertAction(title: "OK", style: .default)
                self.showAlert(withActions: [okAction],
                               ofType: .alert,
                               withMessage: ("Touch ID not available..", "Failed authentication too may times, restart phone to proceed further."),
                               complitionHandler: nil)
            }
        }
    }
}

extension ControllerViewController: UserListDelegate {
    func showHUD(_ show: Bool, withString label: String?) {
        if show {
            if let label = label {
                self.hud.label.text = label
            }
            self.hud.show(animated: true)
        } else {
            self.hud.hide(animated: true)
            self.hud.label.text = nil
        }
    }
}


