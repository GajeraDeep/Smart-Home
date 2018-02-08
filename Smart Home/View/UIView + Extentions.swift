//
//  Extraclass.swift
//  Smart Home
//
//  Created by Deep Gajera on 18/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit

extension UIView {
    func setShadowWithHeight(_ height: Int, shadowRadius: CGFloat, opacity: Float) {
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0, height: height)
        self.layer.shadowColor = UIColor(red: 22/255.0, green: 60/255.0, blue: 81/255.0, alpha: 1.0).cgColor
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOpacity = opacity
    }
    
    func fadeIn() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1.0
        }
    }
    
    func fadeOut() {
        UIView.animate(withDuration: 0.4) {
            self.alpha = 0
        }
    }
    
    func recenter() {
        self.center = CGPoint(x: (superview?.frame.width)! / 2, y: (superview?.frame.height)! / 2)
    }
}

