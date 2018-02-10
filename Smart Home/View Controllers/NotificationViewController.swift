//
//  NotificationViewController.swift
//  Smart Home
//
//  Created by Deep Gajera on 17/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import Firebase

final class Notification {
    var uid: String
    var name: String = ""
    var state: SecurityState
    var timstamp: TimeInterval
    
    static var idToNameDict: [String: String] = [:]
    
    init(uid: String, state: Int, timstamp: TimeInterval) {
        self.uid = uid
        self.timstamp = timstamp
        self.state = SecurityState(rawValue: state)!
    }
    
    func getUserName(forId id: String, complitionHandler: @escaping (String) -> ()) {
        if let _name = Notification.idToNameDict[id] {
            complitionHandler(_name)
        } else {
            Fire.shared.getUser(UID: id, { (userData) in
                if let _name = userData["name"] as? String {
                    Notification.idToNameDict[self.uid] = _name
                    complitionHandler(_name)
                }
            })
        }
    }
}

class NotificationTableViewCell: UITableViewCell {
    @IBOutlet weak var modifierName: UILabel!
    @IBOutlet weak var secModifications: UILabel!
    @IBOutlet weak var timeAgo: UILabel!
}

class NotificationViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private let refreshControl = UIRefreshControl()
    let dateFormatter = DateFormatter()
    var notifications: [Notification] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.tableView.allowsSelection = false
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        startNotificationObserver()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(refreshTabel), for: .valueChanged)
    }

    @objc func refreshTabel() {
        tableView.reloadData()
        
        refreshControl.endRefreshing()
    }
    
    func startNotificationObserver() {
        let notificationRef = Fire.shared.database.child("notifications/\(Fire.shared.myCID!)")
        
        notificationRef.observe(.childAdded) { (snapshot) in
            //let name = snapshot.childSnapshot(forPath: "/modifierID").value as? String
            
            if let dict = snapshot.value as? [String: Any] {
                guard let uid = dict["modifierID"] as? String else { return }
                guard let newState = dict["newState"] as? Int else { return }
                guard let timestamp = dict["timestamp"] as? TimeInterval else { return }

                let notification = Notification(uid: uid, state: newState, timstamp: timestamp)
                notification.getUserName(forId: uid, complitionHandler: { (name) in
                    if !name.isEmpty {
                        notification.name = name
                        self.notifications.insert(notification, at: 0)
                    }
                })
            }
        }
    }
}

extension NotificationViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.notificationTBViewCell.rawValue, for: indexPath) as? NotificationTableViewCell {
            let notification = notifications[indexPath.row]
            
            cell.modifierName.text = notification.name
            cell.secModifications.text = {
                switch notification.state {
                case .enabled:
                    return "Enabled Security."
                case .dissabled:
                    return "Dissabled Security."
                case .breached:
                    return "Security Breached."
                }
            }()
            cell.timeAgo.text = dateFormatter.timeSince(from: NSDate.init(timeIntervalSince1970: notification.timstamp))
            
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        UIView.animate(withDuration: 0.2) {
            cell.alpha = 1
        }
    }
}

extension DateFormatter {
    func timeSince(from: NSDate, numericDates: Bool = false) -> String {
        let calendar = Calendar.current
        let now = NSDate()
        let earliest = now.earlierDate(from as Date)
        let latest = earliest == now as Date ? from : now
        let components = calendar.dateComponents([.year, .weekOfYear, .month, .day, .hour, .minute, .second], from: earliest, to: latest as Date)
        
        var result = ""
        
        if components.year! >= 2 {
            result = "\(components.year!) years ago"
        } else if components.year! >= 1 {
            if numericDates {
                result = "1 year ago"
            } else {
                result = "Last year"
            }
        } else if components.month! >= 2 {
            result = "\(components.month!) months ago"
        } else if components.month! >= 1 {
            if numericDates {
                result = "1 month ago"
            } else {
                result = "Last month"
            }
        } else if components.weekOfYear! >= 2 {
            result = "\(components.weekOfYear!) weeks ago"
        } else if components.weekOfYear! >= 1 {
            if numericDates {
                result = "1 week ago"
            } else {
                result = "Last week"
            }
        } else if components.day! >= 2 {
            result = "\(components.day!) days ago"
        } else if components.day! >= 1 {
            if numericDates {
                result = "1 day ago"
            } else {
                result = "Yesterday"
            }
        } else if components.hour! >= 2 {
            result = "\(components.hour!) hours ago"
        } else if components.hour! >= 1 {
            if numericDates {
                result = "1 hour ago"
            } else {
                result = "An hour ago"
            }
        } else if components.minute! >= 2 {
            result = "\(components.minute!) mins ago"
        } else if components.minute! >= 1 {
            if numericDates {
                result = "1 min ago"
            } else {
                result = "A min ago"
            }
        } else if components.second! >= 3 {
            result = "\(components.second!) secs ago"
        } else {
            result = "Just now"
        }
        
        return result
    }
}
