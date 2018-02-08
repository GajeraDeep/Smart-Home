//
//  TabBarViewControler.swift
//  Smart Home
//
//  Created by Deep Gajera on 17/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit

class TabBarViewControler: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tabBar.unselectedItemTintColor = UIColor(red: 50/255.0, green: 50/255.0, blue: 50/255.0, alpha: 1.0)
        self.tabBar.tintColor = UIColor(red: 30/255.0, green: 174/255.0, blue: 255/255.0, alpha: 1.0)
    
        self.tabBar.alpha = 0
    }


}
