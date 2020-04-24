//
//  CoordinatorHelper.swift
//  PivoBasicSDKTestApp
//
//  Created by Tuan on 2020/04/13.
//  Copyright © 2020 3i. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

struct CoordinatorHelper {
  
  /// Convert a rect in image view coordinate system to a rect in image coordinate system
  /// - Parameters:
  ///   - imageContainerViewSize: size of the view that contains the image
  ///   - imageContainerViewContentMode: How the view display the image, support 2 types: scaleFit ans scaleFill
  ///   - imageSize: the image's size
  ///   - rectToConvert: a rect in image view coordinate system (origin point is the (0, 0) point of the image view)
  /// - Returns: a rect in image coordinate system
  static func convertImageViewCoordinateToImageCoordinate(imageContainerViewSize: CGSize,
                                                          imageContainerViewContentMode: AVLayerVideoGravity,
                                                          imageSize: CGSize,
                                                          rectToConvert: CGRect) -> CGRect {
    
    let containerViewWidth = imageContainerViewSize.width
    let containerViewHeight = imageContainerViewSize.height
    
    var ratio: CGFloat = 1
    let widthRatio = containerViewWidth / imageSize.width
    let heightRatio = containerViewHeight / imageSize.height
    
    var previewOriginalX: CGFloat = 0
    var previewOriginalY: CGFloat = 0
    
    switch imageContainerViewContentMode {
    case .resizeAspect:
      if imageSize.height * widthRatio < containerViewHeight {
        ratio = widthRatio
        previewOriginalY = (containerViewHeight - imageSize.height * ratio) / 2
      }
      else {
        ratio = heightRatio
        previewOriginalX = (containerViewWidth - imageSize.width * ratio) / 2
      }
    case .resizeAspectFill:
      if imageSize.height * widthRatio < containerViewHeight {
        ratio = heightRatio
        previewOriginalX = (containerViewWidth - imageSize.width * ratio) / 2
      }
      else {
        ratio = widthRatio
        previewOriginalY = (containerViewHeight - imageSize.height * ratio) / 2
      }
    default:
      break
    }
    
    let x = rectToConvert.origin.x - previewOriginalX
    let y = rectToConvert.origin.y - previewOriginalY
    
    let imageX = x / ratio
    let imageY = y / ratio
    let width = rectToConvert.size.width / ratio
    let height = rectToConvert.size.height / ratio
    
    return CGRect(x: imageX, y: imageY, width: width, height: height)
  }
  
  /// Convert a rect in image coordinate system to a rect in container image view coordinate system
  /// - Parameters:
  ///   - imageContainerViewSize: size of the view that contains the image
  ///   - imageContainerViewContentMode: How the view display the image, support 2 types: resizeAspect ans scaleFill
  ///   - imageSize: the image's size
  ///   - rectToConvert: a rect in image coordinate system
  /// - Returns: a rect in container image view coordinate system
  static func convertImageCoordinateToImageViewCoordinate(imageContainerViewSize: CGSize,
                                                          imageContainerViewContentMode: AVLayerVideoGravity,
                                                          imageSize: CGSize,
                                                          rectToConvert: CGRect) -> CGRect {
    
    let containerViewWidth = imageContainerViewSize.width
    let containerViewHeight = imageContainerViewSize.height
    
    var ratio: CGFloat = 1
    let widthRatio = containerViewWidth / imageSize.width
    let heightRatio = containerViewHeight / imageSize.height
    
    var previewOriginalX: CGFloat = 0
    var previewOriginalY: CGFloat = 0
    
    switch imageContainerViewContentMode {
    case .resizeAspect:
      if imageSize.height * widthRatio < containerViewHeight {
        ratio = widthRatio
        previewOriginalY = (containerViewHeight - imageSize.height * ratio) / 2
      }
      else {
        ratio = heightRatio
        previewOriginalX = (containerViewWidth - imageSize.width * ratio) / 2
      }
    case .resizeAspectFill:
      if imageSize.height * widthRatio < containerViewHeight {
        ratio = heightRatio
        previewOriginalX = (containerViewWidth - imageSize.width * ratio) / 2
      }
      else {
        ratio = widthRatio
        previewOriginalY = (containerViewHeight - imageSize.height * ratio) / 2
      }
    default:
      break
    }
    
    let x = rectToConvert.origin.x * ratio
    let y = rectToConvert.origin.y * ratio
    
    let imageX  = x + previewOriginalX
    let imageY  = y + previewOriginalY
    let width   = rectToConvert.size.width * ratio
    let height  = rectToConvert.size.height * ratio
    
    return CGRect(x: imageX, y: imageY, width: width, height: height)
  }
  
  static func rotatePointInsideImage(imageSize: CGSize, point: CGPoint, rotateAngle: CGFloat) -> CGPoint {
    
    let midX = imageSize.width / 2
    let midY = imageSize.height / 2
    
    let dx = cos(rotateAngle) * (point.x - midX) + sin(rotateAngle) * (point.y - midY)
    let dy = -sin(rotateAngle) * (point.x - midX) + cos(rotateAngle) * (point.y - midY)
    
    let x = midY - dx
    let y = midX - dy
    
    return CGPoint(x: x, y: y)
  }
  
  /// Rotate a rect inside the image when the image rotate
  /// - Parameters:
  ///   - imageSize: image size
  ///   - rect: rect that needs to be rotated
  ///   - rotateAngle: rotate angle in radians
  static func rotateRectInsideImage(imageSize: CGSize, rect: CGRect, rotateAngle: CGFloat) -> CGRect {
    
    let p1 = CGPoint(x: rect.minX, y: rect.minY)
    let p2 = CGPoint(x: rect.minX, y: rect.maxY)
    let p3 = CGPoint(x: rect.maxX, y: rect.minY)
    let p4 = CGPoint(x: rect.maxX, y: rect.maxY)
    
    let rotatedP1 = rotatePointInsideImage(imageSize: imageSize, point: p1, rotateAngle: rotateAngle)
    let rotatedP2 = rotatePointInsideImage(imageSize: imageSize, point: p2, rotateAngle: rotateAngle)
    let rotatedP3 = rotatePointInsideImage(imageSize: imageSize, point: p3, rotateAngle: rotateAngle)
    let rotatedP4 = rotatePointInsideImage(imageSize: imageSize, point: p4, rotateAngle: rotateAngle)
    
    let minX = min(rotatedP1.x, rotatedP2.x, rotatedP3.x, rotatedP4.x)
    let maxX = max(rotatedP1.x, rotatedP2.x, rotatedP3.x, rotatedP4.x)
    let minY = min(rotatedP1.y, rotatedP2.y, rotatedP3.y, rotatedP4.y)
    let maxY = max(rotatedP1.y, rotatedP2.y, rotatedP3.y, rotatedP4.y)
    
    return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
  }
  
}
