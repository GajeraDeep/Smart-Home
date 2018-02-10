//
//  UsersListProvider.swift
//  Smart Home
//
//  Created by Deep Gajera on 06/02/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import Firebase
import MBProgressHUD

protocol UserListDelegate {
    func showHUD(_ show: Bool, withString label: String?)
}

class UserList: NSObject {
    
    private let verifiedUsersPath: String
    private let rejectedUserPath: String
    private let waitingUserPath: String
    
    private var dhandle: DatabaseHandle?
    private var tableView: UITableView
    
    private var previuosUids = [String]()
    private var flushedUser: CUser?
    
    private var keysArray: [ControllerAccessState] = [.accepted, .waiting, .denied]
    var usersDict: [ControllerAccessState: [CUser]] = {
        let dict: [ControllerAccessState: [CUser]] = [
            .accepted: [],
            .waiting : [],
            .denied: []
        ]
        return dict
    }()
    
    var enableEditing = false {
        didSet {
            if enableEditing {
                enableEditingTableView()
            } else {
                stopEditingTableView()
            }
        }
    }
    
    var delegate: UserListDelegate?
    
    init(CID: String, tableView: UITableView) {
        verifiedUsersPath = "verifiedUsers/" + CID
        rejectedUserPath = "rejectedUsers/" + CID
        waitingUserPath = "requests/" + CID
        self.tableView = tableView
    }
    
    func enableEditingTableView() {
        if let vUsers = usersDict[.accepted] {
            let newVUsers = vUsers.filter({ (user) -> Bool in
                if user.uid == Fire.shared.myUID {
                    flushedUser = user
                } else {
                    return true
                }
                return false
            })
            usersDict.updateValue(newVUsers, forKey: .accepted)
        }
        
        removeObserver()

        DispatchQueue.global(qos: .default).async {
            self.fillNonVerifiedUsers()
        }
    }
    
    private func stopEditingTableView() {
        self.tableView.isEditing = false
        
        DispatchQueue.global(qos: .default).async {
            self.applyChanges { (succedded) in
                if succedded {
                    DispatchQueue.main.async {
                        if let fUser = self.flushedUser {
                            if var users = self.usersDict[.accepted] {
                                users.append(fUser)
                                users.sort(by: < )
                                
                                self.usersDict.updateValue(users, forKey: .accepted)
                            }
                        }
                        self.usersDict[.denied] = []
                        self.usersDict[.waiting] = []
                        self.usersDict[.accepted] = []
                        
                        self.previuosUids = []
                        self.startObserver()
                    }
                }
            }
        }
    }
    
    private func fillNonVerifiedUsers() {
        var progress: Int = 0 {
            didSet {
                if progress == 100 {
                    DispatchQueue.main.async {
                        self.delegate?.showHUD(false, withString: nil)
                        self.tableView.reloadData()
                        self.tableView.isEditing = true
                    }
                }
            }
        }
        var rejectedUsers = [CUser]()
        getUIDs(rejectedUserPath) { (exists, uids) in
            if exists, uids != [] {
                for uid in uids {
                    self.getCUser(uid, withState: nil, complitionHandler: { (user) in
                        if let usr = user {
                            rejectedUsers.append(usr)
                        }
                        if rejectedUsers.count == uids.count {
                            rejectedUsers.sort(by: < )
                            self.usersDict.updateValue(rejectedUsers, forKey: ControllerAccessState.denied)
                            progress += 50
                        }
                    })
                }
            } else {
                progress += 50
            }
        }
        
        var waitingUsers = [CUser]()
        getUIDs(waitingUserPath) { (exists, uids) in
            if exists, uids != [] {
                for uid in uids {
                    self.getCUser(uid, withState: nil, complitionHandler: { (user) in
                        if let usr = user {
                            waitingUsers.append(usr)
                        }
                        if waitingUsers.count == uids.count {
                            waitingUsers.sort(by: < )
                            self.usersDict.updateValue(waitingUsers, forKey: ControllerAccessState.waiting)
                            progress += 50
                        }
                    })
                }
            } else {
                progress += 50
            }
        }
    }
    
    private func applyChanges(complitionHandler: @escaping (_ success: Bool) -> ()) {
        var progress: Int = 0 {
            didSet {
                if progress == 100 {
                    complitionHandler(true)
                }
            }
        }
        
        if let users = usersDict[.accepted] {
            if users.isEmpty {
                progress += 50
            } else {
                var count = users.count {
                    didSet {
                        if count == 0 {
                            progress += 50
                        }
                    }
                }
                for user in users {
                    if let state = user.initialAccessState, state != .accepted {
                        change(user, from: user.initialAccessState!, to: .accepted, withSecModState: user.allowSecMod, complitionHandler: { success in
                            count -= 1
                        })
                    } else if let _ = user.userIsModified, let state = user.allowSecMod {
                        Fire.shared.setData(state, at: verifiedUsersPath + "/" + user.uid + "/" + "securityChanges", complitionHandler: {
                            success, _ in
                            count -= 1
                        })
                    } else {
                        count -= 1
                    }
                }
            }
        }
        if let users = usersDict[.denied] {
            if users.isEmpty {
                progress += 50
            }  else {
                var count = users.count {
                    didSet {
                        if count == 0 {
                            progress += 50
                        }
                    }
                }
                
                for user in users {
                    if let state = user.initialAccessState, state != .denied {
                        change(user, from: user.initialAccessState!, to: .denied, withSecModState: nil, complitionHandler: {
                            success in
                            count -= 1
                        })
                    } else {
                        count -= 1
                    }
                }
            }
        }
    }
    
    private func change(_ user: CUser, from previuosState: ControllerAccessState, to newState: ControllerAccessState, withSecModState modState: Bool?, complitionHandler: @escaping (Bool) -> ()) {
        let previousPath: String = self.path(withId: user.uid, for: previuosState)
        
        Fire.shared.removeData(at: previousPath, complitionHandler: { success in
            var newPath = self.path(withId: user.uid, for: newState)
            
            if modState != nil {
                newPath += "/securityChanges"
            }
            
            Fire.shared.setData(modState ?? true, at: newPath, complitionHandler: { (success, _) in
                Fire.shared.setData(newState.toInt, at: "users/\(user.uid)/accessState", complitionHandler: { (success, _) in
                    complitionHandler(success)
                })
            })
        })
    }
    
    func path(withId uid: String, for state: ControllerAccessState) -> String {
        switch state {
        case .accepted:
            return verifiedUsersPath + "/" + uid
        case .waiting:
            return waitingUserPath + "/" + uid
        case .denied:
            return rejectedUserPath + "/" + uid
        }
    }
    
    private func getCUser(_ uid: String, withState modState: Bool?, complitionHandler: @escaping (_ cUser: CUser?) -> () ) {
        Fire.shared.getUser(UID: uid) { (userData) in
            if let name = userData["name"] as? String {
                let user = CUser(name: name, uid: uid)
                
                if let isHead = userData["isHead"] as? Int, isHead == 1 {
                    if Fire.shared.myUID == uid {
                        user.type = .meAndHead
                    } else {
                        user.type = .head
                    }
                } else if uid == Fire.shared.myUID {
                    user.type = .me
                }
                if let state = modState {
                    user.allowSecMod = state
                }
                complitionHandler(user)
            }
        }
    }
    
    private func getUIDs(_ path: String, complitionHandler: @escaping (Bool,[String]) -> ()) {
        Fire.shared.doesDataExist(at: path) { (doesExists, data) in
            if doesExists {
                if let dict = data as? NSDictionary {
                    if let keys = dict.allKeys as? [String] {
                        complitionHandler(true,keys)
                    }
                }
            } else {
                complitionHandler(false, [])
            }
        }
    }
    
    func startObserver() {
        dhandle = Fire.shared.database.child(verifiedUsersPath).observe(.value) { (snapshot) in

            var uids = [String]()
            var secModStates: [String : Bool] = [:]
            for child in snapshot.children {
                if let child = child as? DataSnapshot {
                    uids.append(child.key)
                }
            }
            
            let newUids = uids.filter({ (uid) -> Bool in
                if !self.previuosUids.contains(uid) {
                    if let dict = snapshot.value as? NSDictionary {
                        if let data = dict[uid] as? NSDictionary{
                            if let state = data["securityChanges"] as? Bool {
                                secModStates[uid] = state
                            }
                        }
                    }
                }
                return !(self.previuosUids.contains(uid))
            })
            
            var users: [CUser] = []
            
            for uid in newUids {
                self.getCUser(uid, withState: secModStates[uid], complitionHandler: { (user) in
                    if let _usr = user {
                        users.append(_usr)
                    }
                    if users.count == newUids.count {
                        if let oldUsers = self.usersDict[.accepted] {
                            users.append(contentsOf: oldUsers)
                        }
                        users.sort(by: < )
                        self.usersDict.updateValue(users, forKey: .accepted)
                        self.tableView.reloadData()
                        
                        DispatchQueue.main.async {
                            self.delegate?.showHUD(false, withString: nil)
                        }
                    }
                })
            }
            self.previuosUids.append(contentsOf: newUids)
        }
    }
    
    func removeObserver() {
        if let handle = dhandle {
            Fire.shared.database.child(verifiedUsersPath).removeObserver(withHandle: handle)
        }
    }
}


extension UserList: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        if enableEditing {
            let keys = usersDict.keys
            return keys.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let users = usersDict[keysArray[section]] {
            return users.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.cUserCell.rawValue, for: indexPath)  as? CUserTableViewCell {
            
            if let users = usersDict[keysArray[indexPath.section]] {
                let user = users[indexPath.row]
                cell.name = user.name
                cell.userType = user.type
                if let state = user.allowSecMod, enableEditing {
                    cell.secSwitch.isHidden = false
                    cell.secSwitch.isOn = state
                } else {
                    cell.secSwitch.isHidden = true
                }
                cell.delegate = self
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return enableEditing ? 40 : 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView : UIView = {
            if enableEditing {
                return UIView(frame: CGRect(origin: .zero, size: CGSize(width: 375, height: 40)))
            } else {
                return UIView(frame: CGRect(origin: .zero, size: CGSize(width: 375, height: 60)))
            }
        }()
        
        headerView.backgroundColor = UIColor(red: 236/255.0, green: 240/255.0, blue: 241/255.0, alpha: 1)
        
        let userType = keysArray[section]
        let users = usersDict[userType]
        
        let label = UILabel(frame: .zero)

        let headerString = enableEditing ? userType.rawValue : "Users (\(users?.count ?? 0))"
        label.font = UIFont(name: "Nunito-SemiBold.ttf", size: 15)
        label.text = "\(headerString)"
        label.textColor = UIColor(red: 9/255.0, green: 52/255.0, blue: 77/255.0, alpha: 1)
        label.sizeToFit()
        
        headerView.addSubview(label)
        label.recenter()
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == 0, enableEditing {
            return .delete
        } else {
            return .insert
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let cell = tableView.cellForRow(at: indexPath) as? CUserTableViewCell {
            if cell.userType == .meAndHead {
                return false
            }
        }

        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        tableView.beginUpdates()
        
        if editingStyle == .delete {
            let fromUserType = keysArray[indexPath.section]
            if var users = usersDict[fromUserType] {
                let user = users[indexPath.row]
                
                user.allowSecMod = nil
                user.userIsModified = true
                user.initialAccessState == nil ? (user.initialAccessState = fromUserType) : nil
                
                if var deniedUsers = usersDict[.denied] {
                    deniedUsers.append(user)
                    usersDict.updateValue(deniedUsers, forKey: .denied)
                    
                    let newUsers = users.filter ({
                        $0 != user
                    })
                    usersDict.updateValue(newUsers, forKey: fromUserType)
                }
            }
            
            let cell = tableView.cellForRow(at: indexPath) as! CUserTableViewCell
            cell.secSwitch.isHidden = true
            
            let index = IndexPath(row: 0, section: 2)
            tableView.moveRow(at: indexPath, to: index)
        } else if editingStyle == .insert {
            let fromUserType = keysArray[indexPath.section]
            
            if var users = usersDict[fromUserType] {
                let user = users[indexPath.row]
                user.allowSecMod = false
                
                user.initialAccessState == nil ? (user.initialAccessState = fromUserType) : nil
                
                if var verifiedUsers = usersDict[.accepted] {
                    verifiedUsers.append(user)
                    usersDict.updateValue(verifiedUsers, forKey: .accepted)
                    
                    let newUsers = users.filter ({
                        $0 != user
                    })
                    usersDict.updateValue(newUsers, forKey: fromUserType)
                }
            }
            
            let index = IndexPath(row: 0, section: 0)
            tableView.moveRow(at: indexPath, to: index)
            
            let cell = tableView.cellForRow(at: indexPath) as! CUserTableViewCell
            cell.secSwitch.isHidden = false
            cell.secSwitch.isOn = false
        }
        
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        if let users = usersDict[keysArray[section]] {
            if users.isEmpty {
                let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 375, height: 45)))
                
                let label = UILabel(frame: .zero)
                label.font = label.font.withSize(15)
                label.textColor = UIColor(red: 9/255.0, green: 52/255.0, blue: 77/255.0, alpha: 0.4)
                label.text = "No user data"
                label.sizeToFit()
                
                view.addSubview(label)
                label.recenter()
                
                return view
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let  users = usersDict[keysArray[section]] {
            if users.isEmpty {
                return 45
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        UIView.animate(withDuration: 0.2 * indexPath.row.toDouble()) {
            cell.alpha = 1
        }
    }
}

extension Int  {
    func toDouble() -> Double {
        return Double(self)
    }
}

extension UserList: CUserTableViewCellDelegate {
    func switchChangedState(_ forCell: CUserTableViewCell, to state: Bool) {
        let indexPath = tableView.indexPath(for: forCell)!
        
        if let users = usersDict[keysArray[indexPath.section]] {
            let user = users[indexPath.row]
            user.allowSecMod = state
            
            user.userIsModified = true
        }
    }
}
















