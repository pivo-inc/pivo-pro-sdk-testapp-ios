//
//  AppDelegate.swift
//  RotatorTestApp
//
//  Created by Tuan on 2020/02/21.
//  Copyright © 2020 3i. All rights reserved.
//

import UIKit
import PivoProSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    
    if let vc = SelectPivoVC.storyboardInstance() {
      window?.rootViewController = vc
      window?.makeKeyAndVisible()
    }
    
    if let licenseFileURL = Bundle.main.url(forResource: "licenseKey", withExtension: "json") {
      do {
        try PivoProSDK.shared.unlockWithLicenseKey(licenseKeyFileURL: licenseFileURL)
      }
      catch {
        print(error)
      }
    }
    
    return true
  }

}

