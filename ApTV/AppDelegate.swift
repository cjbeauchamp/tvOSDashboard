//
//  AppDelegate.swift
//  ApTV
//
//  Created by Chris Beauchamp on 3/17/16.
//  Copyright © 2016 Apteligent. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // if we've never set the settings, initialize them with the Apteligent demo keys here
        if (NSUserDefaults.standardUserDefaults().objectForKey("appID") == nil) {
            NSUserDefaults.standardUserDefaults().setObject("519d53101386202089000007", forKey: "appID")
            NSUserDefaults.standardUserDefaults().setObject("fPQbB9AQanBQsabRhQW27HKYfpwgkqsO", forKey: "accessToken")
            NSUserDefaults.standardUserDefaults().synchronize()
        }

        return true
    }

}

