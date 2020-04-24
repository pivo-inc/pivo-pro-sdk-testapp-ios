//
//  DeviceOrientation.swift
//  PivoProSDKTestApp
//
//  Created by Tuan on 2020/04/17.
//  Copyright © 2020 3i. All rights reserved.
//

import Foundation
import CoreMotion
import UIKit

protocol DeviceOrientationDelegate {
  func didDeviceOrientationChanged(deviceOrientation: UIDeviceOrientation, statusBarOrientation: UIInterfaceOrientation)
}

class DeviceOrientation {
  
  var delegate: DeviceOrientationDelegate?
  private let motionManager: CMMotionManager
  private var deviceOrientation: UIDeviceOrientation!
  private var statusBarOrientation: UIInterfaceOrientation!
  
  init() {
    motionManager = CMMotionManager()
    initMotionManager()
  }
  
  func initMotionManager() {
    motionManager.accelerometerUpdateInterval = 0.1
    
    let accelerometerQueue = OperationQueue()
    motionManager.startAccelerometerUpdates(to: accelerometerQueue, withHandler: { [weak self]
      (accelerometerData, error) -> Void in
      guard error == nil else {
        print(error!)
        return
      }
      guard let data = accelerometerData else { return }
      
      self?.outputAccelertionData(data.acceleration)
    })
  }
  
  func outputAccelertionData(_ acceleration: CMAcceleration) {
    var orientation: UIDeviceOrientation
    var barOrientation: UIInterfaceOrientation = .portrait
    
    DispatchQueue.main.sync {
      barOrientation = UIApplication.shared.statusBarOrientation
    }
    
    if acceleration.x >= 0.75 {
      orientation = .landscapeRight
    }
    else if acceleration.x <= -0.75 {
      orientation = .landscapeLeft
    }
    else if acceleration.y <= -0.75 {
      orientation = .portrait
    }
    else if acceleration.y >= 0.75 {
      orientation = .portraitUpsideDown
    }
    else {
      return
    }
    
    if orientation == deviceOrientation && barOrientation == statusBarOrientation {
      return
    }
    
    deviceOrientation = orientation
    statusBarOrientation = barOrientation
    delegate?.didDeviceOrientationChanged(deviceOrientation: orientation, statusBarOrientation: barOrientation)
  }
  
}
