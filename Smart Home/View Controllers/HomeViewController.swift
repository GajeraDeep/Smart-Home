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

class HomeViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var securityButton: UIButton!
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var appliancesLabel: UILabel!
    @IBOutlet weak var securityStateLabel: UILabel!
    @IBOutlet weak var messageView: MessageView!
    
    let appliances = AppliancesType.applianceArray
    
    var allowSecModifications: Bool?
    var isUserPresent: Bool?
    
    let securityButtonView: SecurityButtonView = {
        let view = SecurityButtonView(frame: CGRect(x: 75, y: 77, width: 225, height: 225))
        view.backgroundColor = UIColor.clear
        view.alpha = 0
        return view
    }()
    
    var hud: MBProgressHUD!
    
    var databaseConection: Bool? = nil {
        willSet {
            if newValue != databaseConection {
                if let newVal = newValue, newVal {
                    if messageView.isVisible {
                        let bgColor = UIColor(red: 0, green: 179/255.0, blue: 0, alpha: 1)
                        messageView.changeStillMessage("Back Online", color: bgColor, completionHandler: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
                                self.messageView.removeStillMessage()
                            })
                        })
                    }
                } else {
                    if !messageView.isVisible {
                        messageView.showStillMessage("No connection")
                    }
                }
            }
        }
    }
    
    var interfaceType: InterfaceType = .loading {
        willSet {
            switch newValue {
            case .loading:
                self.fadeAndDissableViews(true)
                hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.isUserInteractionEnabled = false
                hud.label.text = "Loading.."
                
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
                        self.tabBarController?.selectedViewController = self
                        
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
            StatesManager.initManager(uid: Fire.shared.myUID!, cid: Fire.shared.myCID!)
            StatesManager.manager?.delegate = self
        }
        
        let handler: (Bool) -> () = { state in
            if self.databaseConection == nil, !Reachability.isConnectedToNetwork() {
                self.interfaceType = .noInternetConnection
            } else {
                if state == Reachability.isConnectedToNetwork() {
                    self.databaseConection = state
                }
            }
        }
        Fire.shared.connChangeshandlers.append(handler)
        
        self.messageView.initMessage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        StatesManager.manager?.delegate = self
        
        if !((StatesManager.manager?.doesHandlerExist(forKeys: [.fan, .light])) ?? true) {
            StatesManager.manager?.startObservers(forKeys: [.fan, .light])
        }
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
            if let val = databaseConection, val {
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
            let alert = UIAlertController(title: "Modifications denied..", message: "You don't have enough permissions to modify security state", preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
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
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            if let handler = successHandler {
                handler()
            }
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func menuBarButtonPressed(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let logOut = UIAlertAction(title: "Log Out", style: .destructive) { _ in
            do {
                if let _ = Auth.auth().currentUser {
                    
                    Fire.shared.stopMainObservers()
                    StatesManager.manager?.delegate = nil
                    StatesManager.manager = nil
                    
                    try Auth.auth().signOut()
                    
                    let signInVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: StoryBoardIDs.signInVC.rawValue)
                    signInVC.heroModalAnimationType = .slide(direction: .right)
                    self.hero_replaceViewController(with: signInVC)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        logOut.isEnabled = {
            if let val = databaseConection {
                return val
            }
            return false
        }()
        
        actionSheet.addAction(logOut)
        actionSheet.addAction(cancel)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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
        if let val = databaseConection, val {
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
    }
    
    func accessStateChanged(to: ControllerAccessState) {
        switch to {
        case .accepted:
            if interfaceType != .loading {
                self.interfaceType = .loading
            }

            self.tabBarController?.tabBar.alpha = 1
            
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








