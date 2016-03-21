//
//  SettingsViewController.swift
//  ApTV
//
//  Created by Chris Beauchamp on 3/21/16.
//  Copyright © 2016 Apteligent. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var appIdLabel: UITextField!
    @IBOutlet weak var apiKeyLabel: UITextField!
    
    @IBAction func goBack(sender: UIButton) {
        print("going back")
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func saveSettings(sender: UIButton) {
        print(self.appIdLabel.text)
        print(self.apiKeyLabel.text)
    }

}