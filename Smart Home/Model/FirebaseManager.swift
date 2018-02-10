//
//  FirebaseManager.swift
//  Smart Home
//
//  Created by Deep Gajera on 03/02/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import Firebase

class Fire {
    static let shared = Fire()
    
    var myUID: String?
    var myCID: String?
    
    var connChangeshandlers: [((_ state: Bool) -> ())] = [] {
        didSet {
            if let state = connState {
                connChangeshandlers.forEach({ (handler) in
                    handler(state)
                })
            }
        }
    }
    var userSignedInHandler: (() -> ())?
    
    private var connState: Bool?
    
    private var userStateChangeDHandle: AuthStateDidChangeListenerHandle?
    private var connStateChangeDHandle: DatabaseHandle?
    
    let database: DatabaseReference = Database.database().reference()
    
    fileprivate init ()  {}
    
    func startMainObservers() {
        userStateChangeDHandle = Auth.auth().addStateDidChangeListener { (auth, listnerUser) in
            if let user = listnerUser {
                print("SIGN IN: \(user.email ?? user.uid)")
                self.myUID = user.uid
                self.userExists(user, complitionHandler: { (exists) in
                    if exists {
                        self.doesDataExist(at: "users/\(self.myUID!)/controllerID", compltionHandler: { (idExist, data) in
                            if idExist {
                                if let id = data as? String {
                                    self.myCID = id
                                    if let handler = self.userSignedInHandler {
                                        handler()
                                    }
                                }
                            }
                        })
                    }
                })
            } else {
                self.myUID = nil
                print("SIGN OUT: no user")
            }
        }
        
        let connectionRef = database.child(".info/connected")
        connStateChangeDHandle = connectionRef.observe(.value) { (snap) in
            guard let state = snap.value as? Bool else {
                return
            }
            
            self.connState = state
            self.connChangeshandlers.forEach({ (handler) in
                handler(state)
            })
        }
    }
    
    func stopMainObservers() {
        connChangeshandlers = []
        userSignedInHandler = nil
        
        if let handler = userStateChangeDHandle {
            Auth.auth().removeStateDidChangeListener(handler)
        }
        if let handler = connStateChangeDHandle {
            database.child(".info/connected").removeObserver(withHandle: handler)
        }
    }
    
    func getData(_ childURL: String?, complitionHandler: @escaping (Any?) -> ()) {
        var reference = self.database
        if let url = childURL {
            reference = self.database.child(url)
        }
        reference.observeSingleEvent(of: .value) { (snap) in
            complitionHandler(snap.value)
        }
    }

    func setData(_ object: Any, at path:String, complitionHandler: ((Bool, DatabaseReference) -> ())? ) {
        self.database.child(path).setValue(object) { (error, ref) in
            if let e = error {
                print(e.localizedDescription)
                if let complition = complitionHandler {
                    complition(false, ref)
                }
            } else {
                if let complition = complitionHandler {
                    complition(true, ref)
                }
            }
        }
    }
    
    func setData(_ object: Any, at path:DatabaseReference, complitionHandler: ((Bool, DatabaseReference) -> ())? ) {
        path.setValue(object) { (error, ref) in
            if let e = error {
                print(e.localizedDescription)
                if let complition = complitionHandler {
                    complition(false, ref)
                }
            } else {
                if let complition = complitionHandler {
                    complition(true, ref)
                }
            }
        }
    }
    
    func pushNotification(_ object: Any, complitionHandler: ((Bool) -> ())? ) {
        database.child("notifications").child(myCID!).childByAutoId().setValue(object) { (error, _) in
            if error != nil {
                if let handler = complitionHandler {
                    handler(false)
                }
            } else {
                if let handler = complitionHandler {
                    handler(true)
                }
            }
        }
    }
    
    func doesDataExist(at path:String, compltionHandler: @escaping (_ doesExist: Bool, _ data:Any?) -> () ) {
        self.database.child(path).observeSingleEvent(of: .value) { (snap) in
            if snap.exists() {
                compltionHandler(true, snap.value)
            } else {
                compltionHandler(false, nil)
            }
        }
    }
    
    func getUser(UID: String, _ complitionHandler: @escaping ([String: Any]) -> ()) {
        database.child("users").child(UID).observeSingleEvent(of: .value) { (snap) in
            if let userData = snap.value as? [String: Any] {
                complitionHandler(userData)
            }
        }
    }
    
    func newUser(_ user: User, withData userData: [String: Any]?, complitionHandler: ((_ success: Bool) -> ())? ) {
        var newUser:[String: Any] = [
            "createdAt": Date.init().timeIntervalSince1970
        ]
        
        if let name = user.displayName { newUser["name"] = name }
        if let data = userData {
            guard let cid = data["cid"] as? String else {
                return
            }
            newUser["controllerID"] = cid
            
            if let isHead = data["isHead"] as? Bool, isHead {
                newUser["isHead"] = 1
                setData(user.uid, at: "heads/" + cid, complitionHandler: nil)
                setData(true, at: "verifiedUsers/" + cid + "/" + user.uid + "/securityChanges", complitionHandler: nil)
            } else {
                newUser["accessState"] = 0
                setData(true, at: "requests/" + cid + "/" + user.uid, complitionHandler: nil)
            }
        }
        
        database.child("users").child(user.uid).updateChildValues(newUser) { (error, ref) in
            if let e = error {
                print(e.localizedDescription)
                if let compition = complitionHandler {
                    compition(false)
                }
            } else {
                if let complition = complitionHandler {
                    complition(true)
                }
            }
        }
    }
    
    func removeData(at path: String, complitionHandler: @escaping (Bool) -> ()) {
        database.child(path).removeValue { (error, _ ) in
            if error != nil {
                complitionHandler(true)
            } else {
                complitionHandler(false)
            }
        }
    }
    
    func userExists(_ user: User, complitionHandler: @escaping (Bool) -> ()) {
        self.database.child("users").child(user.uid).observeSingleEvent(of: .value) { (snap) in
            if snap.value != nil {
                complitionHandler(true)
            } else {
                complitionHandler(false)
            }
        }
    }
}
