//
//  ImageHelper.swift
//  PivoProSDKTestApp
//
//  Created by Tuan on 2020/04/14.
//  Copyright © 2020 3i. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

struct ImageHelper {
  
  static let context = CIContext()
  
  static func image(from sampleBuffer: CMSampleBuffer) -> UIImage? {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
    let ciImage = CIImage(cvPixelBuffer: imageBuffer)
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
    return UIImage(cgImage: cgImage)
  }
}
