//
//  ApplianceCollectionViewCell.swift
//  Smart Home
//
//  Created by Deep Gajera on 26/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit

protocol ApplianceCollectionViewCellDelegate {
    func applianceStateChangedTo(_ state: Bool, forAppliance appliance: AppliancesType)
}

enum AppliancesType: String {
    case light = "Light"
    case fan = "Fan"
    
    static var applianceArray : [AppliancesType] {
        return [.light, .fan]
    }
}

class ApplianceCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var applianceNameLabel: UILabel!
    
    var animationView: (UIView & AnimationViewProtocol)?
    var applianceType: AppliancesType!
    
    var state: Bool = false {
        willSet {
            if newValue != state {
                stateLabel.text = newValue.stateString
                newValue ? animationView?.turnOnAnimation() : animationView?.turnOffAnimation()
            }
        }
    }
    
    var delegate: ApplianceCollectionViewCellDelegate?
    
    func setupCell(forAppliance appliance: AppliancesType, withState state: Bool) {
        self.layer.cornerRadius = 5
        self.setShadowWithHeight(0, shadowRadius: 10, opacity: 0.21)
        
        applianceNameLabel.text = appliance.rawValue
        stateLabel.text = state.stateString
        
        self.applianceType = appliance
        self.state = state

        loadView()
        
        self.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.itemTapped(_:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    func loadView() {
        var view: (UIView & AnimationViewProtocol)? = nil
        
        switch applianceType {
        case .light:
            let lightView = BulbView()
            lightView.frame.origin = CGPoint(x: 58, y: 46)
            
            view = lightView
        case .fan:
            let fanView = FanView()
            fanView.frame.origin = CGPoint(x: 53, y: 70)
            
            view = fanView
        default:
            print("")
        }
        
        state ? view?.turnOnAnimation() : nil
        animationView = view
        self.addSubview(animationView ?? UIView())
    }
    
    @objc func itemTapped(_ sender: UITapGestureRecognizer) {
        delegate?.applianceStateChangedTo((state) ? false : true, forAppliance: applianceType)
    }
}

extension Bool {
    var stateString: String {
        get {
            return self ? "On" : "Off"
        }
    }
}
