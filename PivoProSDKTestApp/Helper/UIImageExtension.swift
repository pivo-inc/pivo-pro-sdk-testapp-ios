//
//  UIImageExtension.swift
//  PivoProSDKTestApp
//
//  Created by Tuan on 2020/04/17.
//  Copyright © 2020 3i. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
  func rotate(radians: CGFloat) -> UIImage? {
    var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: radians)).size
    // Trim off the extremely small float value to prevent core graphics from rounding it up
    newSize.width = floor(newSize.width)
    newSize.height = floor(newSize.height)
    
    UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
    let context = UIGraphicsGetCurrentContext()!
    
    // Move origin to middle
    context.translateBy(x: newSize.width/2, y: newSize.height/2)
    // Rotate around middle
    context.rotate(by: CGFloat(radians))
    
    self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
    
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
  }
}
