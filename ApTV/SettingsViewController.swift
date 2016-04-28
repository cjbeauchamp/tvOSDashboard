//
//  SettingsViewController.swift
//  ApTV
//
//  Created by Chris Beauchamp on 3/21/16.
//  Copyright © 2016 Apteligent. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    // connectors for our UI elements
    @IBOutlet weak var appIdField: UITextField!
    @IBOutlet weak var accessTokenField: UITextField!
    
    // anytime the settings appears, pre-load the user settings
    // into the user interface
    override func viewWillAppear(animated: Bool) {
        
        // if the appID exists in settings, load it into the UI field
        if let appID = NSUserDefaults.standardUserDefaults().objectForKey("appID") {
            self.appIdField.text = appID as? String
        }
        
        // if the access token exists in settings, load it into the UI field
        if let accessToken = NSUserDefaults.standardUserDefaults().objectForKey("accessToken") {
            self.accessTokenField.text = accessToken as? String
        }
    }
    
    // triggered when the user selects the save button
    @IBAction func saveSettings(sender: UIButton) {
        
        // appID and accessToken are stored into the NSUserDefaults
        NSUserDefaults.standardUserDefaults().setObject(self.appIdField.text, forKey: "appID")
        NSUserDefaults.standardUserDefaults().setObject(self.accessTokenField.text, forKey: "accessToken")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // the UI is popped to the main screen
        self.navigationController?.popViewControllerAnimated(true)
    }

}