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

class CUser: Comparable {
    var name: String
    var uid: String
    var type: CUserType
    var allowSecMod: Bool?
    
    var userIsModified: Bool?
    var initialAccessState: ControllerAccessState?
    
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

class UsersManager {
    static let shared: UsersManager = UsersManager()
    
    var verifiedUsers: [CUser] = [] {
        didSet {
            print(verifiedUsers.count)
        }
    }
    var waitingUser: [CUser] = [] {
        didSet {
            print(waitingUser)
        }
    }
    
    private var databaseHandles: [ControllerAccessState: [DatabaseHandle]] = [:]
    
    fileprivate init() {}
    
    func startObserver(forUserWithState state: ControllerAccessState, complitionHandler: ((Bool) -> ())? ) {
        let path = state.pathWith(cid: Fire.shared.myCID!)
        
        getChildrenCount(forPath: path) { (count) in
            if count > 0 {
                var usersFetched = 0 {
                    didSet {
                        if usersFetched == count {
                            if let handler = complitionHandler {
                                handler(true)
                            }
                        }
                    }
                }
                
                if !(self.doesObserverExists(forUsersInState: state)) {
                    let childAddedHandle = Fire.shared.database.child(path)
                        .observe(.childAdded, with: { (snapshot) in
                            Fire.shared.getUser(UID: snapshot.key, { (userData) in
                                guard let name = userData["name"] as? String else { return }
                                let user = CUser(name: name, uid: snapshot.key)
                                
                                switch state {
                                case .accepted:
                                    if snapshot.key == Fire.shared.myUID {
                                        if let isHead = userData["isHead"] as? Int, isHead == 1 {
                                            user.type  = .meAndHead
                                        } else {
                                            user.type = .me
                                        }
                                    } else if let isHead = userData["isHead"] as? Int, isHead == 1 {
                                        user.type  = .head
                                    }
                                    
                                    user.allowSecMod = snapshot.childSnapshot(forPath: "securityChanges").value as? Bool
                                    self.verifiedUsers.append(user)
                                    
                                    if usersFetched != count { usersFetched += 1 }
                                    
                                case .waiting:
                                    self.waitingUser.append(user)
                                    
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
                    
                    self.databaseHandles[state] = []
                    self.databaseHandles[state]?.append(childAddedHandle)
                    self.databaseHandles[state]?.append(childRemovedHandle)
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
            if databaseHandles[.accepted] != nil {
                return true
            }
        case .waiting:
            if databaseHandles[.waiting] != nil {
                return true
            }
        case .denied:
            if databaseHandles[.denied] != nil {
                return true
            }
        }
        return false
    }
    
    func removeObservers(forStates states: [ControllerAccessState]) {
        for state in states {
            if doesObserverExists(forUsersInState: state), let handles = databaseHandles[state] {
                for handle in handles {
                    Fire.shared.database.child(state.pathWith(cid: Fire.shared.myCID!)).removeObserver(withHandle: handle)
                }
            }
        }
    }
    
    func getChildrenCount(forPath: String, complitonHandler: @escaping (Int) -> () ) {
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
    
    func fetchListOfRejectedUsers(complitionHandler: @escaping (Bool, [CUser]) ->()) {
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
                            Fire.shared.getUser(UID: uid, { (userData) in
                                guard let name = userData["name"] as? String else { return }
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
    
    private func change(_ user: CUser, from previuosState: ControllerAccessState, to newState: ControllerAccessState, withSecModState modState: Bool?, complitionHandler: @escaping (Bool) -> ()) {
        let previousPath: String = previuosState.pathWith(cid: Fire.shared.myCID!) + "/" + user.uid
        
        Fire.shared.removeData(at: previousPath, complitionHandler: { success in
            if success {
                var newPath = newState.pathWith(cid: Fire.shared.myCID!) + "/" + user.uid
                
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
