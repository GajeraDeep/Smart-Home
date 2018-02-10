//
//  MessageView.swift
//  Smart Home
//
//  Created by Deep Gajera on 05/02/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit

class MessageView: UIView {
    
    var label = UILabel(frame: CGRect.zero)
    
    var isVisible: Bool = false
    
    func initMessage() {
        self.alpha = 0
        self.addSubview(label)
        self.label.font = label.font.withSize(12)
    }
    
    func showStillMessage(_ str: String) {
        self.backgroundColor = UIColor.darkGray
        
        label.text = str
        label.textColor = UIColor.white
        label.sizeToFit()
        label.recenter()
        
        isVisible = true
        
        UIView.animate(withDuration: 0.8, animations: {
            self.alpha = 1
        })
    }
    
    func flashStillMessage() {
        UIView.animate(withDuration: 0.2, animations: {
            self.backgroundColor = UIColor.lightGray
        }) { (success) in
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = UIColor.darkGray
            }
        }
    }
    
    func changeStillMessage(_ to: String, color: UIColor, completionHandler: (() -> ())? ) {
        label.text = "Back Online"
        label.sizeToFit()
        label.recenter()
            
        UIView.animate(withDuration: 0.5, animations: {
            self.backgroundColor = color
        }, completion: { success in
            if let handler = completionHandler {
                handler()
            }
        })
    }
    
    func removeStillMessage() {
        UIView.animate(withDuration: 0.8) {
            self.alpha = 0
        }
        isVisible = false
    }
    
    func showMessage(_ str: String, forTime: Double) {
        self.backgroundColor = UIColor.darkGray
        
        label.text = str
        label.textColor = UIColor.white
        label.sizeToFit()
        label.recenter()
        
        UIView.animate(withDuration: 0.4, animations: {
            self.alpha = 1
        }) { (success) in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + forTime, execute: {
                    UIView.animate(withDuration: 0.4, animations: {
                        self.alpha = 0
                    })
                })
            }
        }
    }
}
