//
//  Enums.swift
//  Smart Home
//
//  Created by Deep Gajera on 20/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit

enum CellIdentifier: String {
    case applianceCell
    case cUserCell
}

enum AuthAlertType {
    case noInternetAccess
    case recordsDoesNotMatch
    case invalidEmail
    case undefined
    case toManyRequests
    case emailUsed
    case weakPasword
    
    var title: String {
        switch self {
        case .noInternetAccess:
            return "No internt access"
        case .invalidEmail, .recordsDoesNotMatch, .emailUsed, .weakPasword:
            return "Please try again..."
        case .toManyRequests:
            return "Please try later..."
        case .undefined:
            return "Unknown error"
        }
    }
    
    var message: String {
        switch self {
        case .noInternetAccess:
            return "There seems to be no internet connection. Please check your connection and try again."
        case .invalidEmail:
            return "Email address seems invalid. Please check and try again."
        case .recordsDoesNotMatch:
            return "Username or password doesnot match our records. Please re-check and try again."
        case .emailUsed:
            return "Email already in used. Please try another one."
        case .weakPasword:
            return "Your password is not strong enough. Please enter stronger one."
        case .toManyRequests:
            return "To many requests from your device. Please try later."
        case .undefined:
            return "Unknown error has occured."
        }
    }
}

enum StoryBoardIDs: String {
    case createAccountVC
    case signInVC
    case tabbarVC
    case inputControler_idVC
    case rootVC
    case homeVC
}

enum Colors {
    case attribtedString
    
    var color: UIColor {
        switch self {
        case .attribtedString:
            return UIColor(red: 26/255.0, green: 113/255.0, blue: 161/255.0, alpha: 1.0)
        }
    }
}

enum UsersAccessStatus: Int {
    case waiting = 0
    case rejected = -1
    case active = 1
}

enum UsersSecurityModificationStatus {
    case allowed
    case denied
}
