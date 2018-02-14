//
//  UsersManager.swift
//  Smart Home
//
//  Created by Deep Gajera on 10/02/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import Foundation
import Firebase

enum CUserType {
    case normal
    case head
    case me
    case meAndHead
}

extension Int  {
    func toDouble() -> Double {
        return Double(self)
    }
}

struct CUser: Comparable {
    var name: String
    var uid: String
    var type: CUserType
    var allowSecMod: Bool?
    
    var userIsModified: Bool?
    var sourceAccessState: ControllerAccessState?
    
    init(name: String, uid: String) {
        self.name = name
        self.uid = uid
        self.type = .normal
    }
    
    static func <(lhs: CUser, rhs: CUser) -> Bool {
        return lhs.name < rhs.name
    }
    
    static func ==(lhs: CUser, rhs: CUser) -> Bool {
        return lhs.uid == rhs.uid
    }
}

protocol UserManagerDelegate {
    func verifiedUserChanged()
    func waitingUserChanged()
}

extension UserManagerDelegate {
    func verifiedUserChanged() {}
    func waitingUserChanged() {}
}

class UsersManager {
    static let shared: UsersManager = UsersManager()
    
    var usersMap: [String: String] = [:]
    
    var verifiedUsers: [CUser] = [] {
        didSet {
            delegates.forEach({
                $0.verifiedUserChanged()
            })
        }
    }
    var waitingUser: [CUser] = [] {
        didSet {
            delegates.forEach({
                $0.waitingUserChanged()
            })
        }
    }
    
    private var databaseHandles: [ControllerAccessState: [DatabaseHandle]] = [
        .accepted: [],
        .waiting: []
    ]
    
    var delegates: [UserManagerDelegate] = []
    
    fileprivate init() {}
    
    func startObserver(forUserWithState state: ControllerAccessState, complitionHandler: ((Bool) -> ())? ) {
        let path = state.pathWith(cid: Fire.shared.myCID!)
        
        getChildrenCount(forPath: path) { (count) in
            if count > 0 {
                var usersFetched = 0 {
                    didSet {
                        if usersFetched == count {
                            if let handler = complitionHandler {
                                state == .accepted ? self.verifiedUsers.sort() : self.waitingUser.sort()
                                handler(true)
                            }
                        }
                    }
                }
                
                if !(self.doesObserverExists(forUsersInState: state)) {
                    let childAddedHandle = Fire.shared.database.child(path)
                        .observe(.childAdded, with: { (snapshot) in
                            Fire.shared.getUserName(UID: snapshot.key, { (name) in
                                var user = CUser(name: name, uid: snapshot.key)
                                
                                switch state {
                                case .accepted:
                                    let uid = snapshot.key
                                    let headID = StatesManager.manager?.headID
                                    
                                    if uid == Fire.shared.myUID {
                                        if uid == headID {
                                            user.type = .meAndHead
                                        } else {
                                            user.type = .me
                                        }
                                    } else if uid == headID {
                                        user.type = .head
                                    } else {
                                            user.type = .normal
                                    }
                                    
                                    user.allowSecMod = snapshot.childSnapshot(forPath: "securityChanges").value as? Bool
                                    self.verifiedUsers.append(user)
                                    
                                    if usersFetched != count {
                                        usersFetched += 1
                                    } else {
                                        self.verifiedUsers.sort()
                                    }
                                    
                                case .waiting:
                                    self.waitingUser.append(user)
                                    if usersFetched != count {
                                        usersFetched += 1
                                    } else {
                                        self.waitingUser.sort()
                                    }
                                    
                                default:
                                    fatalError("Unexpected key passed to Users Manager, start observer")
                                }
                            })
                        })
                    
                    let childRemovedHandle = Fire.shared.database.child(path)
                        .observe(.childRemoved, with: { (snapshot) in
                            switch state {
                            case .accepted:
                                self.verifiedUsers = self.verifiedUsers.filter({ (user) -> Bool in
                                    user.uid != snapshot.key
                                })
                            case .waiting:
                                self.waitingUser = self.waitingUser.filter({ (user) -> Bool in
                                    user.uid != snapshot.key
                                })
                            default:
                                fatalError("Unexpected key passed to Users Manager, start observer")
                            }
                        })
                    
                    self.databaseHandles[state]?.insert(contentsOf: [childAddedHandle, childRemovedHandle], at: 0)
                }
            } else {
                if let handler = complitionHandler {
                    handler(true)
                }
            }
        }
    }
    
    func doesObserverExists(forUsersInState state: ControllerAccessState) -> Bool {
        switch state {
        case .accepted:
            if let handles = databaseHandles[state], !handles.isEmpty {
                return true
            }
        case .waiting:
            if let handles = databaseHandles[state], !handles.isEmpty {
                return true
            }
        default:
            fatalError("unknown key entered")
        }
        return false
    }
    
    func removeObservers(forStates states: [ControllerAccessState]) {
        for state in states {
            if doesObserverExists(forUsersInState: state), let handles = databaseHandles[state] {
                for handle in handles {
                    Fire.shared.database.child(state.pathWith(cid: Fire.shared.myCID!)).removeObserver(withHandle: handle)
                }
                databaseHandles[state] = []
            }
        }
        
        verifiedUsers = []
        waitingUser = []
    }
    
    private func getChildrenCount(forPath: String, complitonHandler: @escaping (Int) -> () ) {
        Fire.shared.doesDataExist(at: forPath) { (doesExist, data) in
            if doesExist {
                if let dict = data as? NSDictionary {
                    complitonHandler(dict.allKeys.count)
                }
            } else {
                complitonHandler(0)
            }
        }
    }
    
    private func fetchListOfRejectedUsers(complitionHandler: @escaping (Bool, [CUser]) ->()) {
        let state = ControllerAccessState.denied
        var users = [CUser]()
        
        var count = 0 {
            didSet {
                if count == 0 {
                    complitionHandler(true, users)
                    return
                } else if count == -1 {
                    complitionHandler(false, [])
                }
            }
        }
        
        Fire.shared.doesDataExist(at: state.pathWith(cid: Fire.shared.myCID!)) { (doesExist, data) in
            if doesExist {
                if let dict = data as? NSDictionary {
                    if let uids = dict.allKeys as? [String] {
                        count = uids.count
                        for uid in uids {
                            Fire.shared.getUserName(UID: uid, { (name) in
                                let user = CUser(name: name, uid: uid)
                                users.append(user)
                                
                                count -= 1
                            })
                        }
                    }
                }
            } else {
                count = -1
            }
        }
    }
    
    func getDublicateUsersDict(complitionHandler: @escaping ([ControllerAccessState: [CUser]]) -> () ) {
        let myUID = Fire.shared.myUID!
        let filteredUsers = verifiedUsers.filter { (user) -> Bool in
            user.uid != myUID
        }
        
        var dict: [ControllerAccessState: [CUser]] = [
            .accepted: filteredUsers,
            .waiting: waitingUser
        ]
        
        fetchListOfRejectedUsers { (doesExist, users) in
            if doesExist {
                dict[.denied] = users
            } else {
                dict[.denied] = []
            }
            complitionHandler(dict)
        }
    }
    
    func syncChangesInDublicateDict(_ usersDict: [ControllerAccessState: [CUser]], complitionHandler: @escaping (Bool) -> () ) {
        
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
                    if let state = user.sourceAccessState, state != .accepted {
                        change(user, from: user.sourceAccessState!, to: .accepted, withSecModState: user.allowSecMod ?? false, complitionHandler: { success in
                            count -= 1
                        })
                    } else if let _ = user.userIsModified, let state = user.allowSecMod {
                        Fire.shared.setData(state, at: ControllerAccessState.accepted.pathWith(cid: Fire.shared.myCID!) + "/" + user.uid + "/" + "securityChanges", complitionHandler: {
                            success, _ in
                            
                            // MARK: - Modifing verified users array as per modifications
                            if let index = self.verifiedUsers.index(of: user) {
                                self.verifiedUsers.replaceSubrange(index...index, with: [user])
                            }
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
                    if let state = user.sourceAccessState, state != .denied {
                        change(user, from: user.sourceAccessState!, to: .denied, withSecModState: nil, complitionHandler: {
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
        let cid = Fire.shared.myCID!
        
        let previousPath: String = previuosState.pathWith(cid: cid) + "/" + user.uid
        
        Fire.shared.removeData(at: previousPath, complitionHandler: { success in
            if success {
                var newPath = newState.pathWith(cid: cid) + "/" + user.uid
                
                if modState != nil {
                    newPath += "/securityChanges"
                }
                
                Fire.shared.setData(modState ?? true, at: newPath, complitionHandler: { (success, _) in
                    if success {
                        Fire.shared.setData(newState.toInt, at: "users/\(user.uid)/accessState", complitionHandler: { (success, _) in
                            complitionHandler(success)
                        })
                    } else {
                        complitionHandler(false)
                    }
                })
            } else {
                complitionHandler(false)
            }
        })
    }
}
