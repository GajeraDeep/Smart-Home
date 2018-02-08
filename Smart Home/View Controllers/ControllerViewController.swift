//
//  ControllerViewController.swift
//  Smart Home
//
//  Created by Deep Gajera on 17/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import MBProgressHUD

class ControllerViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageView: MessageView!
    
    var hud: MBProgressHUD!
    
    var userListProvider: UserList!
    
    var databaseConection: Bool? = nil {
        willSet {
            if newValue != databaseConection {
                if let newVal = newValue, newVal {
                    if messageView.isVisible {
                        let bgColor = UIColor(red: 0, green: 179/255.0, blue: 0, alpha: 1)
                        messageView.changeStillMessage("Back Online", color: bgColor, completionHandler: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
                                self.messageView.removeStillMessage()
                            })
                        })
                    }
                } else {
                    if !messageView.isVisible {
                        messageView.showStillMessage("No connection")
                    }
                    hud.hide(animated: true)
                }
            }
        }
    } 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hud = MBProgressHUD.init()
        hud.label.text = "Loading.."
        
        self.view.addSubview(hud)
        hud.show(animated: true)
        
        userListProvider = UserList(CID: Fire.shared.myCID!, tableView: self.tableView)
        userListProvider.delegate = self
        
        self.tableView.allowsSelection = false
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        self.tableView.delegate = userListProvider
        self.tableView.dataSource = userListProvider
        
        self.messageView.initMessage()
        
        let handler: (Bool) -> () = { state in
            if state == Reachability.isConnectedToNetwork() {
                self.databaseConection = state
            }
        }
        Fire.shared.connChangeshandlers.append(handler)
        
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
        if self.userListProvider.enableEditing {
            hud.label.text = "Syncing.."
            hud.show(animated: true)
            
            self.userListProvider.enableEditing = false
            self.navigationItem.leftBarButtonItem?.title = "Edit"
        } else {
            hud.label.text = "Fetching.."
            hud.show(animated: true)

            self.userListProvider.enableEditing = true
            self.navigationItem.leftBarButtonItem?.title = "Done"
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


