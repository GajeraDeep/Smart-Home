//
//  ControllerTableViewClasses.swift
//  Smart Home
//
//  Created by Deep Gajera on 01/02/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit

protocol CUserTableViewCellDelegate {
    func switchChangedState(_ forCell: CUserTableViewCell, to state: Bool)
}

class CUserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var userCategoryLabel: UILabel!
    @IBOutlet weak var secSwitch: UISwitch!
    
    var delegate: CUserTableViewCellDelegate?
    
    var name: String? {
        get {
            return self.nameLabel.text
        }
        set {
            self.nameLabel.text = newValue
        }
    }
    
    /**
     will always return normal
    */
    var userType: CUserType {
        get {
            return .normal
        }
        set {
            switch newValue {
            case .head:
                self.userCategoryLabel.text = "Head"
                self.userCategoryLabel.textColor = UIColor(red: 240/255.0, green: 39/255.0, blue: 39/255.0, alpha: 0.65)
                self.userCategoryLabel.isHidden = false
            case .me:
                self.userCategoryLabel.textColor = UIColor.lightGray
                self.userCategoryLabel.text = "me"
                self.userCategoryLabel.isHidden = false
            case .normal:
                self.userCategoryLabel.isHidden = true
            case .meAndHead:
                self.userCategoryLabel.text = "Me"
                self.userCategoryLabel.textColor = UIColor(red: 240/255.0, green: 39/255.0, blue: 39/255.0, alpha: 0.65)
                self.userCategoryLabel.isHidden = false
            }
        }
    }
    
    @IBAction func switchTapped(_ sender: UISwitch) {
        delegate?.switchChangedState(self, to: sender.isOn)
    }
}













