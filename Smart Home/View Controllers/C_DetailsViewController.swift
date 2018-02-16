//
//  C_DetailsViewController
//  Smart Home
//
//  Created by Deep Gajera on 17/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import LocalAuthentication

class C_DetailsViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableTopConstraint: NSLayoutConstraint!
    
    var dublicateDict: [ControllerAccessState: [CUser]]? = nil
    
    var rightBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.backgroundColor = self.view.backgroundColor
        
        self.tableView.allowsSelection = false
        self.tableView.tableFooterView = UIView(frame: .zero)
        
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
        
        UsersManager.shared.delegates.append(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if tableView.isEditing {
            stopEditing()
        }
    }
    
    func setEditBarButtonItem() {
        let editButItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editBarItemPressed(_:)))
        self.navigationItem.leftBarButtonItem = editButItem
    }
    
    @objc func editBarItemPressed(_ sender: UIBarButtonItem) {
        if messageView.isVisible {
            messageView.flashStillMessage()
        } else {
            if tableView.isEditing {
                if let userDict = dublicateDict {
                    hud.label.text = "Syncing.."
                    hud.show(animated: true)
                    UsersManager.shared.syncChangesInDublicateDict(userDict, complitionHandler: { (success) in
                        self.stopEditing()
                    })
                }
            } else {
                authenticateUser(complitionHandler: { (doesSuccedd) in
                    if doesSuccedd {
                        self.rightBarButtonItem = self.navigationItem.rightBarButtonItem
                        
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancelEditing(_:)))
                        
                        self.hud.label.text = "Fetching.."
                        self.hud.show(animated: true)
                        
                        UsersManager.shared.getDublicateUsersDict(complitionHandler: { (userDict) in
                            self.dublicateDict = userDict
                            
                            self.tableView.isEditing = true
                            sender.title = "Done"
                            
                            self.tableView.reloadData()
                            self.hud.hide(animated: true)
                            
                            UIView.animate(withDuration: 0.2, animations: {
                                self.tableHeightConstraint.priority = UILayoutPriority(rawValue: 1)
                                self.tableTopConstraint.priority = UILayoutPriority(rawValue: 999)
                                self.view.layoutIfNeeded()
                            })
                        })
                    }
                })
            }
        }
    }
    
    @objc func cancelEditing(_ sender: UIBarButtonItem) {
        stopEditing()
    }
    
    func stopEditing() {
        self.dublicateDict = nil
        
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
        self.navigationItem.leftBarButtonItem?.title = "Edit"
        
        self.tableView.isEditing = false
        self.hud.hide(animated: true)
        self.tableView.reloadData()
        
        UIView.animate(withDuration: 0.2, animations: {
            self.tableTopConstraint.priority = UILayoutPriority(rawValue: 1)
            self.tableHeightConstraint.priority = UILayoutPriority(rawValue: 999)
            self.view.layoutIfNeeded()
        })
    }
    
    private func authenticateUser(complitionHandler: @escaping (_ success: Bool) -> () ) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Please identify yourself!"
            
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: reason) {
                success, error in
                DispatchQueue.main.async {
                    complitionHandler(success)
                }
            }
        } else {
            if let code = error?.code, code == kLAErrorBiometryLockout {
                
                let okAction = UIAlertAction(title: "OK", style: .default)
                self.showAlert(withActions: [okAction],
                               ofType: .alert,
                               withMessage: ("Touch ID not available..", "Failed authentication too may times, restart phone to proceed further."),
                               complitionHandler: nil)
            }
        }
    }
}

extension C_DetailsViewController: UITableViewDelegate, UITableViewDataSource {
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////// Data Source of table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView.isEditing {
            return 3
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.isEditing {
            if let userDict = dublicateDict {
                if let users = userDict[ControllerAccessState.keys[section]] {
                    return users.count
                }
            }
        } else {
            return UsersManager.shared.verifiedUsers.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.cUserCell.rawValue) as! CUserTableViewCell
        var user: CUser!
        
        if tableView.isEditing {
            if let userDict = dublicateDict {
                if let users = userDict[ControllerAccessState.keys[indexPath.section]] {
                    user = users[indexPath.row]
                }
            }
            let isSectionEqualToZero = indexPath.section == 0
            
            cell.secSwitch.isHidden = !isSectionEqualToZero
            isSectionEqualToZero ? cell.secSwitch.isOn = user.allowSecMod ?? false : nil
        } else {
            user = UsersManager.shared.verifiedUsers[indexPath.row]
            cell.secSwitch.isHidden = true
        }
        
        cell.delegate = self
        cell.nameLabel.text = user.name
        cell.userType = user.type
        
        return cell
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////// Re-arrangement logic of table
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath.section != destinationIndexPath.section {
            if let userDict = dublicateDict {
                
                let sourceAccessState = ControllerAccessState.keys[sourceIndexPath.section]
                if var users = userDict[sourceAccessState] {
                    var user = users[sourceIndexPath.row]
                    users.remove(at: sourceIndexPath.row)
                    dublicateDict?.updateValue(users, forKey: sourceAccessState)
                    
                    user.sourceAccessState = sourceAccessState
                    
                    if var newUsers = userDict[ControllerAccessState.keys[destinationIndexPath.section]] {
                        newUsers.insert(user, at: destinationIndexPath.row)
                        dublicateDict?.updateValue(newUsers, forKey: ControllerAccessState.keys[destinationIndexPath.section])
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != 1 && proposedDestinationIndexPath.section == 1 {
            if sourceIndexPath.section == 2 {
                return IndexPath(row: 0, section: sourceIndexPath.section)
            } else if sourceIndexPath.section == 0 {
                return IndexPath(row: tableView.numberOfRows(inSection: 0) - 1, section: sourceIndexPath.section)
            }
        }
        return proposedDestinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////// Header and footer for table
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor(red: 9/255.0, green: 52/255.0, blue: 77/255.0, alpha: 1)
        
        if tableView.isEditing {
            let text: String = {
                switch section {
                case 0:
                    return "Verified"
                case 1:
                    return "Waiting"
                case 2:
                    return "Rejected"
                default:
                    fatalError("Section value out of order")
                }
            }()
            
            label.text = text
        } else {
            label.text = "Users (\(UsersManager.shared.verifiedUsers.count))"
        }
        
        label.sizeToFit()
        
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.frame.width, height: 50)))
        view.backgroundColor = self.view.backgroundColor
        view.addSubview(label)
        label.recenter()
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let userDict = dublicateDict {
            if let users = userDict[ControllerAccessState.keys[section]] {
                if tableView.isEditing, users.isEmpty {
                    let lable = UILabel(frame: .zero)
                    lable.text = "No users data"
                    lable.textColor = UIColor.lightGray
                    lable.font = lable.font.withSize(13)
                    lable.sizeToFit()
                    
                    let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.frame.width, height: 30)))
                    view.backgroundColor = self.view.backgroundColor
                    
                    view.addSubview(lable)
                    lable.recenter()
                    
                    return view
                }
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let userDict = dublicateDict {
            if let users = userDict[ControllerAccessState.keys[section]] {
                if tableView.isEditing, users.isEmpty {
                    return 30
                }
            }
        }
        return 0
    }
}

extension C_DetailsViewController: UserManagerDelegate {
    func verifiedUserChanged() {
        tableView.reloadData()
    }
    
    func waitingUserChanged() {
        let count = UsersManager.shared.waitingUser.count
        self.tabBarController?.tabBar.items?.last?.badgeValue = count > 0 ? String(count) : nil
    }
}

extension C_DetailsViewController: CUserTableViewCellDelegate {
    func switchChangedState(_ forCell: CUserTableViewCell, to state: Bool) {
        guard let indexPath = tableView.indexPath(for: forCell) else {
            return
        }
        
        let accessState = ControllerAccessState.keys[indexPath.section]
        
        if let userDict = dublicateDict {
            if var users = userDict[accessState] {
                var user = users[indexPath.row]
                user.userIsModified = true
                user.allowSecMod = state
                
                users.replaceSubrange(indexPath.row...indexPath.row, with: [user])
                
                dublicateDict?.updateValue(users, forKey: accessState)
            }
        }
    }
}
