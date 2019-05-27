//
//  AppDelegate.swift
//  FacePDFViewer
//
//  Created by cgi on 15/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import UIKit
import ARKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        /*guard let window = window else { return false }
        
        let view = UIView(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        view.backgroundColor = UIColor.green
        let viewCotroller = UIViewController(nibName: nil, bundle: nil)
        viewCotroller.view = view
        
        
        let rootViewController = window.rootViewController
        window.rootViewController = viewCotroller
        if let rootViewController = rootViewController {
            window.rootViewController?.present(rootViewController, animated: false, completion: nil)
        }*/
        
        // 이렇게하면 UIViewController 하나밖에 안뜸
        /*
        let view = UIView(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        let viewController = UIViewController(nibName: nil, bundle: nil)
        viewController.view = view
        
        if let window = UIApplication.shared.delegate?.window ?? nil {
            window.rootViewController = viewController
        }
        */
        
        return true
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


}

class TestViewController: UIViewController {
    
}

