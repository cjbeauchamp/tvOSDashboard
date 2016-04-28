//
//  SettingsViewController.swift
//  ApTV
//
//  Created by Chris Beauchamp on 3/21/16.
//  Copyright © 2016 Apteligent. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var appIdField: UITextField!
    @IBOutlet weak var accessTokenField: UITextField!
    
    override func viewWillAppear(animated: Bool) {
        
        if let appID = NSUserDefaults.standardUserDefaults().objectForKey("appID") {
            self.appIdField.text = appID as? String
        }
        
        if let accessToken = NSUserDefaults.standardUserDefaults().objectForKey("accessToken") {
            self.accessTokenField.text = accessToken as? String
        }
    }
    
    @IBAction func saveSettings(sender: UIButton) {
        NSUserDefaults.standardUserDefaults().setObject(self.appIdField.text, forKey: "appID")
        NSUserDefaults.standardUserDefaults().setObject(self.accessTokenField.text, forKey: "accessToken")
        NSUserDefaults.standardUserDefaults().synchronize()
        self.navigationController?.popViewControllerAnimated(true)
    }

}