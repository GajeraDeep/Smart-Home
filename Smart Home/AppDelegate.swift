//
//  AppDelegate.swift
//  Smart Home
//
//  Created by Deep Gajera on 06/01/18.
//  Copyright © 2018 Deep Gajera. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let attrs = [NSAttributedStringKey.font: UIFont(name: "Nunito-ExtraBold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attrs
        
        FirebaseApp.configure()

        _ = Fire.shared

        let userDefaults = UserDefaults.standard
        if userDefaults.value(forKey: "appFirstTimeOpened") == nil {
            userDefaults.set(true, forKey: "appFirstTimeOpened")
            try? Auth.auth().signOut()
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window = UIWindow(frame: UIScreen.main.bounds)

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rootViewController: UIViewController

        if Auth.auth().currentUser != nil {
            rootViewController = storyboard.instantiateViewController(withIdentifier: StoryBoardIDs.tabbarVC.rawValue)
        } else {
            rootViewController = storyboard.instantiateViewController(withIdentifier: StoryBoardIDs.signInVC.rawValue)
        }

        self.window?.rootViewController = rootViewController
        self.window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        StatesManager.manager?.removeObservers(forKeys: [.contAccess, .fan, .light ,.security, .allowSecMod])
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        StatesManager.manager?.startObservers(forKeys: [.contAccess])
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
    }


}

