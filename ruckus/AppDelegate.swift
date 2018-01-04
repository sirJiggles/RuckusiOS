//////
//  AppDelegate.swift
//  ruckus
//
//  Created by Gareth on 01/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit
import HealthKit
import SwiftyStoreKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WatchNotificationBridgeDelegate {

    var window: UIWindow?
    var bridge: WatchNotificationBridge?
    var intervalTimerSettings =  IntervalTimerSettingsHelper()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let env = ProcessInfo.processInfo.environment
        if let uiTests = env["UITESTS"], uiTests == "1" {
            // remove local storage for user tests
            // reset user defaults
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        }
        
        Fabric.with([Crashlytics.self])
        
        // init the bridge if it does not exist
        if (bridge == nil) {
            bridge = WatchNotificationBridge.sharedInstance
            bridge?.delegate = self
            if bridge?.messageSession == nil {
                bridge?.setUpSession()
            }
            
            // when the watch requests settings do what we do when the session is fist set up,
            // send them
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didSettupSession),
                name: NSNotification.Name(NotificationKey.RequestUserDefaultsFromWatch.rawValue),
                object: nil
            )
            
        }
        
        // set as never go to sleep
        UIApplication.shared.isIdleTimerDisabled = true
        
        // check for old purchases on user defaults
        let paid = UserDefaults.standard.bool(forKey: "proVersion")
        PurchasedState.sharedInstance.isPaid = paid
        
        // if the bundle id is pro, set as paid. this and do not do the store kit
        // checking
        if Bundle.main.bundleIdentifier == "garethfuller.ruckus" {
            PurchasedState.sharedInstance.isPaid = true
            UserDefaults.standard.set(true, forKey: "proVersion")
            return true
        }
        
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            
            for purchase in purchases {
                
                if purchase.transaction.transactionState == .purchased || purchase.transaction.transactionState == .restored {
                    
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    
                    // set as paid
                    PurchasedState.sharedInstance.isPaid = true
                    
                    // set also in user defaults as paid
                    UserDefaults.standard.set(true, forKey: "proVersion")
                }
            }
        }
        
        
        return true
    }
    
    @objc func didSettupSession() {
        // set up the listener for a sync of of the settings from the watch
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(NotificationKey.UserDefaultsPayloadFromWatch.rawValue),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.updateUserDefaults),
            name: NSNotification.Name(NotificationKey.UserDefaultsPayloadFromWatch.rawValue),
            object: nil
        )
        
    }
    
    func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
        let storeHelper = WorkoutStoreHelper()
        // ask for auth from the user as they got the prompt on the watch
        storeHelper.getAuth { (authorized, error) -> Void in
            if (authorized) {
                
            } else {
                // @TODO what goes on here
            }
        }
        
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    @objc func updateUserDefaults(_ payload: NSNotification) {
        // update the user defaults for the watch using the app user defaults
        UserDefaults.standard.setValuesForKeys(payload.userInfo as! [String:Any])
        
        // let anyone listening know the settings where updated
        NotificationCenter.default.post(name: Notification.Name(NotificationKey.SettingsSync.rawValue), object: nil)
    }

}

