//
//  HomeViewController.swift
//  Smart Home
//
//  Created by Deep Gajera on 17/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import Firebase
import MBProgressHUD

enum InterfaceType {
    case normal
    case secEnabled
    case secAlert
    case noInternetConnection
    case accessDenied
    case accessWaiting
    case loading
    
    var bgImage: UIImage {
        switch self {
        case .normal, .secEnabled:
            return #imageLiteral(resourceName: "Home_BG")
        case .secAlert:
            return #imageLiteral(resourceName: "Breach_BG")
        case .noInternetConnection:
            return #imageLiteral(resourceName: "no_internet_access")
        case .accessWaiting:
            return #imageLiteral(resourceName: "request_in_queue")
        case .accessDenied:
            return #imageLiteral(resourceName: "request_rejected")
        case .loading:
            return UIImage()
        }
    }
}

class HomeViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var securityButton: UIButton!
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var appliancesLabel: UILabel!
    @IBOutlet weak var securityStateLabel: UILabel!
    
    let appliances = AppliancesType.applianceArray
    
    var allowSecModifications: Bool?
    var isUserPresent: Bool?
    
    let securityButtonView: SecurityButtonView = {
        let view = SecurityButtonView(frame: CGRect(x: 75, y: 77, width: 225, height: 225))
        view.backgroundColor = UIColor.clear
        view.alpha = 0
        return view
    }()

    var interfaceType: InterfaceType = .loading {
        willSet {
            switch newValue {
            case .loading:
                self.fadeAndDissableViews(true)
                hud.show(animated: true)
                
            case .normal:
                if interfaceType == .secEnabled || interfaceType == .secAlert {
                    self.collectionView.fadeIn()
                    self.appliancesLabel.fadeIn()
                } else if interfaceType != .normal {
                    if interfaceType != .loading {  self.bgImage.fadeOut()  }
                    self.hud.hide(animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                        self.bgImage.image = newValue.bgImage
                        self.fadeAndDissableViews(false)
                    })
                }
                
                self.securityStateLabel.text = "Un-Armed"
                
            case .accessDenied, .accessWaiting, .noInternetConnection:
                if interfaceType != newValue {
                    self.hud.hide(animated: true)
                    fadeAndDissableViews(true)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                        self.bgImage.image = newValue.bgImage
                        self.bgImage.fadeIn()
                        
                        self.tabBarController?.tabBar.alpha = 0
                        self.tabBarController?.selectedViewController = self.navigationController
                        
                        self.securityButtonView.removeAllAnimations()
                    })
                    
                    
                }
                
            case .secEnabled, .secAlert:
                self.hud.hide(animated: true)
                
                if interfaceType == .loading {
                    [securityButton, securityButtonView, securityStateLabel, bgImage].forEach {
                        ($0 as? UIView)?.fadeIn()
                    }
                } else if interfaceType == .normal {
                    self.collectionView.fadeOut()
                    self.appliancesLabel.fadeOut()
                }
                
                if newValue == .secEnabled {
                    if interfaceType != .normal { self.bgImage.image = #imageLiteral(resourceName: "Home_BG") }
                    self.securityStateLabel.text = "Armed Away"
                } else {
                    self.bgImage.image = newValue.bgImage
                    self.securityStateLabel.text = "Security Breached"
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.reloadData()
        
        self.view.addSubview(securityButtonView)
        self.view.bringSubview(toFront: securityButton)
        
        self.bgImage.contentMode = .scaleAspectFill
        
        self.isHeroEnabled = true
        
        self.interfaceType = .loading
        
        Fire.shared.startMainObservers()
        
        Fire.shared.userSignedInHandler = {
            Fire.shared.doesDataExist(at: "heads/\(Fire.shared.myCID!)", compltionHandler: { (doesExist, data) in
                let headID = data as? String ?? ""
                StatesManager.initManager(headID: headID)
                StatesManager.manager?.delegate = self
            })
        }
        
        let handler: (Bool) -> () = { state in
            if self.databaseConnection == nil, !Reachability.isConnectedToNetwork() {
                self.interfaceType = .noInternetConnection
            } else {
                if state == Reachability.isConnectedToNetwork() {
                    self.databaseConnection = state
                }
            }
        }
        Fire.shared.connChangeshandlers.append(handler)
        
        self.messageView.initMessage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !((StatesManager.manager?.doesHandlerExist(forKeys: [.fan, .light])) ?? true) {
            StatesManager.manager?.startObservers(forKeys: [.fan, .light])
        }
        
        super.viewWillAppear(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        StatesManager.manager?.removeObservers(forKeys: [.fan, .light])
    }
    
    func fadeAndDissableViews(_ value: Bool) {
        if value {
            bgImage.fadeOut()
            securityButtonView.fadeOut()
            securityButton.fadeOut()
            appliancesLabel.fadeOut()
            securityStateLabel.fadeOut()
            collectionView.fadeOut()
        } else {
            bgImage.fadeIn()
            securityButtonView.fadeIn()
            securityButton.fadeIn()
            appliancesLabel.fadeIn()
            securityStateLabel.fadeIn()
            collectionView.fadeIn()
        }
    }
    
    @IBAction func securityButtonPressed(_ sender: UIButton) {
        if let allow = allowSecModifications, allow {
            if let val = databaseConnection, val {
                if interfaceType == .normal {
                    if let present = isUserPresent {
                        if present {
                            self.messageView.showMessage("User present", forTime: 0.7)
                            self.securityButtonView.addUserPresentAnimation()
                        } else {
                            showAlertForSecurityModification(.dissabled, to: .enabled, successHandler: {
                                StatesManager.manager?.toggelState(forKey: .security)
                            })
                        }
                    }
                } else if interfaceType == .secEnabled {
                    showAlertForSecurityModification(.enabled, to: .dissabled, successHandler: {
                        StatesManager.manager?.toggelState(forKey: .security)
                    })
                } else if interfaceType == .secAlert {
                    showAlertForSecurityModification(.breached, to: .enabled, successHandler: {
                        StatesManager.manager?.toggelState(forKey: .security)
                    })
                } else {
                    StatesManager.manager?.toggelState(forKey: .security)
                }
            } else {
                self.messageView.flashStillMessage()
            }
        } else {
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            self.showAlert(withActions: [okAction],
                           ofType: .alert,
                           withMessage: ("Modifications denied..", "You don't have enough permissions to modify security state"),
                           complitionHandler: nil)
        }
    }
    
    func showAlertForSecurityModification(_ from: SecurityState, to _ : SecurityState, successHandler: (() -> ())? ) {
        var title: String = ""
        var message: String = ""
        
        switch from {
        case .enabled:
            title = "Dissable Security"
            message = "Your are trying to dissable security, are you sure?"
            
        case .dissabled:
            title = "Enable Security"
            message = "Your are trying to Enable security, are you sure?"
            
        case .breached:
            title = "Stop Alarms"
            message = "Your are trying to dissable alarms, are you sure?"
        }
        
        let okAction = UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            if let handler = successHandler {
                handler()
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        self.showAlert(
            withActions: [okAction, cancelAction],
            ofType: .alert,
            withMessage: (title, message),
            complitionHandler: nil)
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mark: - CollectionView delegate and datasource implementation

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return appliances.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier.applianceCell.rawValue, for: indexPath) as? ApplianceCollectionViewCell {
            cell.setupCell(forAppliance: appliances[indexPath.row], withState: false)
            cell.delegate = self
            return cell
        }
        return UICollectionViewCell()
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mark: - Appliance CollectionViewCell Delegate implementation

extension HomeViewController: ApplianceCollectionViewCellDelegate {
    func applianceStateChangedTo(_ state: Bool, forAppliance appliance: AppliancesType) {
        if let val = databaseConnection, val {
            var key: Key
            
            switch appliance {
            case .fan:
                key = .fan
            case .light:
                key = .light
            }
            
            StatesManager.manager?.toggelState(forKey: key)
        } else {
            messageView.flashStillMessage()
        }
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mark: - States Manager Protocol implementation

extension HomeViewController: StatesManagerProtocol {
    func lightStateChanged(to: Bool) {
        if let lightCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? ApplianceCollectionViewCell {
            lightCell.state = to
        }
    }
    
    func fanStateChanged(to: Bool) {
        if let fanCell = self.collectionView.cellForItem(at: IndexPath(row: 1, section: 0)) as? ApplianceCollectionViewCell {
            fanCell.state = to
        }
    }
    
    func securityStateChanged(to: SecurityState, previousState: SecurityState) {
        switch to {
        case .enabled:
            if previousState == .dissabled {
                self.securityButtonView.addEnableSecurityAnimation()
            } else if previousState == .breached {
                self.securityButtonView.addDisableBreachAnimation()
            }
            self.interfaceType = .secEnabled
            
        case .dissabled:
            if previousState == .breached {
                self.securityButtonView.addDissableSecurityWithBreachAnimation()
            } else if previousState == .enabled {
                self.securityButtonView.addDissableSecurityAnimation(completion: { (success) in
                    if success {
                        self.securityButtonView.removeAllAnimations()
                    }
                })
            }
            self.interfaceType = .normal
            
        case .breached:
            self.securityButtonView.addBreachDetectedAnimation()
            self.interfaceType = .secAlert
        }
        self.tabBarController?.tabBar.alpha = 1
    }
    
    func accessStateChanged(to: ControllerAccessState) {
        switch to {
        case .accepted:
            if interfaceType != .loading {
                self.interfaceType = .loading
            }
            
            // MARK: - Start all observers
            
            var fetchingProgress = 0 {
                didSet {
                    if fetchingProgress == 100 {
                        if !StatesManager.manager!.doesHandlerExist(forKeys: [.light]) {
                            let keys: [Key] = StatesManager.manager!.isUserHead ? [.fan, .light, .security] : [.fan, .light, .security, .allowSecMod]
                            StatesManager.manager!.startObservers(forKeys: keys)
                        }
                    }
                }
            }
            
            UsersManager.shared.startObserver(forUserWithState: .accepted, complitionHandler: { (success) in
                fetchingProgress += 50
            })
            
            if StatesManager.manager!.isUserHead {
                UsersManager.shared.startObserver(forUserWithState: .waiting, complitionHandler: { (sucess) in
                    let count = UsersManager.shared.waitingUser.count
                    self.tabBarController?.tabBar.items?.last?.badgeValue = count > 0 ? String(count) : nil
                    
                    fetchingProgress += 50
                })
            } else {
                fetchingProgress += 50
            }

        case .waiting:
            self.interfaceType = .accessWaiting
            
        case .denied:
            self.interfaceType = .accessDenied
        }
    }
    
    func allowSecurityModificationsStateChanged(to: Bool) {
        allowSecModifications = to
    }
    
    func userPresentStateChanged(to: Bool) {
        isUserPresent = to
    }
}

