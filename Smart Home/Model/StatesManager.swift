//
//  StatesManager.swift
//  Smart Home
//
//  Created by Deep Gajera on 04/02/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import Foundation
import Firebase

enum SecurityState: Int {
    case enabled = 1
    case dissabled = 0
    case breached = -1
    
    var normalizedString: String {
        switch self {
        case .enabled:
            return "Armed Away"
        case .dissabled:
            return "Un-Armed"
        case .breached:
            return "Breach Detected"
        }
    }
    
    var infoString: String {
        switch self {
        case .enabled:
            return "Security has been enabled by"
        case .breached:
            return "Security breached"
        default:
            return ""
        }
    }
}

enum ControllerAccessState: String {
    case denied = "Rejected Users"
    case waiting = "Waiting Users"
    case accepted = "Verified Users"
    
    var toInt: Int {
        switch self {
        case .accepted:
            return 1
        case .waiting:
            return 0
        case .denied:
            return -1
        }
    }
    
    func pathWith(cid: String) -> String {
        switch self {
        case .accepted:
            return "verifiedUsers/" + cid
        case .waiting:
            return "requests/" + cid
        case .denied:
            return "rejectedUsers/" + cid
        }
    }
    
    static let keys: [ControllerAccessState] = [.accepted, .waiting, .denied]
}

enum Key {
    case light
    case fan
    case security
    case contAccess
    case allowSecMod
    
    static var allKeys: [Key] = [ .contAccess, .light, .fan, .security, .allowSecMod]
}

protocol StatesManagerProtocol {
    func lightStateChanged(to: Bool)
    func fanStateChanged(to: Bool)
    func securityStateChanged(to: SecurityState, previousState: SecurityState)
    func accessStateChanged(to: ControllerAccessState)
    func allowSecurityModificationsStateChanged(to: Bool)
    func userPresentStateChanged(to: Bool)
}

class StatesManager {
    static var manager: StatesManager? = nil
    
    private let lightPath: DatabaseReference
    private let fanPath: DatabaseReference
    private let securityPath: DatabaseReference
    private let contAccessPath:  DatabaseReference
    private let allowSecChangesPath: DatabaseReference
    private let isHeadPath: String
    private let userPresentPath: DatabaseReference
    
    var delegate: StatesManagerProtocol? {
        didSet {
            if isUserHead {
                self.contAccess = .accepted
                self.allowSecMod = true
            } else {
                startObservers(forKeys: [.contAccess])
            }
        }
    }
    
    private var handlers: [Key : DatabaseHandle] = [:]
    var isUserPresentDHandler: DatabaseHandle?
    
    var stateChangeHandler: ((_ forKey: Key, _ to: Any) -> ())?
    
    var isUserHead: Bool
    var headID: String
    
    private var light: Bool? {
        willSet {
            if newValue != light, let newState = newValue {
                delegate?.lightStateChanged(to: newState)
            }
        }
    }
    private var fan: Bool? {
        willSet {
            if newValue != fan, let newState = newValue {
                delegate?.fanStateChanged(to: newState)
            }
        }
    }
    private var security: SecurityState? {
        willSet {
            if newValue != security, let newState = newValue {
                delegate?.securityStateChanged(to: newState, previousState: security ?? .dissabled)
            }
        }
    }
    private var contAccess: ControllerAccessState? {
        willSet {
            if newValue != contAccess, let newState = newValue {
                delegate?.accessStateChanged(to: newState)
            }
        }
        didSet {
            if contAccess != .accepted {
                removeObservers(forKeys: [.fan, .light, .security, .allowSecMod])
                
                security = nil
                isUserPresent = nil
                allowSecMod = nil
                fan = nil
                light = nil
            }
        }
    }
    private var allowSecMod: Bool? {
        willSet {
            if newValue != allowSecMod, let newState = newValue {
                delegate?.allowSecurityModificationsStateChanged(to: newState)
                if newState {
                    isUserPresentDHandler = userPresentPath.observe(.value, with: { (snap) in
                        if let state = snap.value as? Int {
                            self.isUserPresent = state == 1 ? true : false
                        }
                    })
                } else {
                    if let handler = isUserPresentDHandler {
                        userPresentPath.removeObserver(withHandle: handler)
                    }
                }
            }
        }
    }
    private var isUserPresent: Bool? {
        willSet {
            if newValue != isUserPresent, let newState = newValue {
                delegate?.userPresentStateChanged(to: newState)
            }
        }
    }
    
    fileprivate init(headID: String) {
        let UID = Fire.shared.myUID!
        let CID = Fire.shared.myCID!
        
        let conRef = Fire.shared.database.child("controllers").child(CID)
        
        lightPath = conRef.child("appliances/light")
        fanPath = conRef.child("appliances/fan")
        securityPath = conRef.child("security")
        contAccessPath = Fire.shared.database.child("users/\(UID)/accessState")
        isHeadPath = "users/" + UID + "/isHead"
        allowSecChangesPath = Fire.shared.database.child("verifiedUsers/\(CID)/\(UID)/securityChanges")
        userPresentPath = Fire.shared.database.child("controllers/" + CID + "/userPresent")
        
        self.isUserHead = headID == Fire.shared.myUID!
        self.headID = headID
    }
    
    deinit {
        removeObservers(forKeys: Key.allKeys)
    }
    
    static func initManager(headID: String = "") {
        if manager == nil {
            manager = StatesManager.init(headID: headID)
        }
    }
    
    func toggelState(forKey key: Key) {
        switch key {
        case .light:
            if let state = self.light {
                self.light = !state
                Fire.shared.setData(self.light! ? 1 : 0, at: lightPath, complitionHandler: nil)
            }
        case .fan:
            if let state = self.fan {
                self.fan = !state
                Fire.shared.setData(self.fan! ? 1 : 0, at: fanPath, complitionHandler: nil)
            }
        case .security:
            if let state = self.security {
                if state == .enabled {
                    self.security = .dissabled
                    pushNotificationWith(security!)
                    Fire.shared.setData(0, at: securityPath.child("state"), complitionHandler: nil)
                } else if state == .breached {
                    self.security = .enabled
                    pushNotificationWith(security!)
                    Fire.shared.setData(0, at: securityPath.child("breached"), complitionHandler: nil)
                } else {
                    self.security = .enabled
                    pushNotificationWith(security!)
                    Fire.shared.setData(1, at: self.securityPath.child("state"), complitionHandler: nil)
                }
            }

        default:
            break
        }
    }
    
    private func pushNotificationWith(_ securityState: SecurityState) {
        let dataDict: [String: Any] = [
            "modifierID": Fire.shared.myUID!,
            "timestamp": Date.init().timeIntervalSince1970,
            "newState": securityState.rawValue
        ]
        Fire.shared.pushNotification(dataDict, complitionHandler: nil)
    }
    
    func doesHandlerExist(forKeys keys: [Key]) -> Bool {
        for key in keys {
            if handlers[key] == nil {
                return false
            }
        }
        return true
    }
    
    func startObservers(forKeys keys: [Key]) {
        keys.forEach { (key) in
            switch (key) {
            case .fan:
                handlers[.fan] = fanPath.observe(.value) { (snap) in
                    if let state = snap.value as? Int {
                        self.fan = state == 1 ? true : false
                    }
                }
                
            case .light:
                handlers[.light] = lightPath.observe(.value) { (snap) in
                    if let state = snap.value as? Int {
                        self.light = state == 1 ? true : false
                    }
                }
                
            case .security:
                handlers[.security] = securityPath.observe(.value) { (snap) in
                    if let dict = snap.value as? NSDictionary {
                        if let isEnabled = dict["state"] as? Int, isEnabled == 1 {
                            if let isBreached = dict["breached"] as? Int, isBreached == 1 {
                                self.security = .breached
                            } else {
                                self.security = .enabled
                            }
                        } else {
                            self.security = .dissabled
                        }
                    }
                }
            case .contAccess:
                if !isUserHead {
                    self.handlers[.contAccess] = self.contAccessPath.observe(.value, with: { (snap) in
                        if let state = snap.value as? Int {
                            switch state {
                            case 1:
                                self.contAccess = .accepted
                            case 0:
                                self.contAccess = .waiting
                            case -1:
                                self.contAccess = .denied
                            default:
                                break
                            }
                        }
                    })
                }
            case .allowSecMod:
                if !isUserHead {
                    handlers[.allowSecMod] = allowSecChangesPath.observe(.value, with: { (snap) in
                        if let state =  snap.value as? Int {
                            self.allowSecMod = state == 1 ? true : false
                        }
                    })
                }
            }
        }
    }
    
    func removeObservers(forKeys keys: [Key]) {
        keys.forEach { (key) in
            switch (key) {
            case .fan:
                if let handler = handlers[key] {
                    fanPath.removeObserver(withHandle: handler)
                }
                
            case .light:
                if let handler = handlers[key] {
                    lightPath.removeObserver(withHandle: handler)
                }
                
            case .security:
                if let handler = handlers[key] {
                    securityPath.removeObserver(withHandle: handler)
                }
            case .contAccess:
                if let handler = handlers[key] {
                    contAccessPath.removeObserver(withHandle: handler)
                }
            case .allowSecMod:
                if let handler = handlers[key] {
                    allowSecChangesPath.removeObserver(withHandle: handler)
                }
            }
            handlers[key] = nil
        }
    }
}
