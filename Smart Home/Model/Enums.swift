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
    case notificationTBViewCell
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

