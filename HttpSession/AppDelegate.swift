//
//  AppDelegate.swift
//  HttpRequest
//
//  Created by Shichimitoucarashi on 2018/04/22.
//  Copyright © 2018年 keisuke yamagishi. All rights reserved.
//

import UIKit
import HttpSession

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        TwitterKey.shared.api.key = "NNKAREvWGCn7Riw02gcOYXSVP"
        TwitterKey.shared.api.secret = "pxA18XddLaEvDgonl0ptMBKt54oFCW4GK8ZyPGvbYTitBvH3kM"

        return true
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
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if(url.absoluteString.hasPrefix("httprequest://")){
            let splitPrefix: String = url.absoluteString.replacingOccurrences(of: "httprequest://success?", with: "")
            Twitter.access(token: splitPrefix, success: { (twitterUSer) in
                Twitter.beare(success: {
                    print ("SUCCESS")
                }, failuer: { (responce, error) in
                    print("Error: \(error) responce: \(responce)")
                })
            }, failuer: { (responce, error) in
                print ("Error: \(error) responce: \(responce)")
            })
            
        }
        return true
    }
}
