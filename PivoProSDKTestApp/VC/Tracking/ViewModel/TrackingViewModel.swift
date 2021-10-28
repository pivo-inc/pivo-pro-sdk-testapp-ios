//
//  TrackingViewModel.swift
//  PivoProSDKTestApp
//
//  Created by Tuan on 2020/04/17.
//  Copyright © 2020 3i. All rights reserved.
//

import Foundation
import PivoProSDK
import AVFoundation

enum TrackingState {
  case prepare
  case started
  case updating
  case stopped
}

protocol TrackingViewModelDelegate {
  func trackingStateChanged(_ state: TrackingState)
  func didDetected(targets: [Target])
}

class TrackingViewModel {
  
  var delegate: TrackingViewModelDelegate?
  
  private var pivoSDK = PivoSDK.shared
  private var trackingType: TrackingType = .object
  private var trackingSensitivity: TrackingSensitivity = .normal
  
  private var trackingState: TrackingState = .prepare {
    didSet {
      delegate?.trackingStateChanged(trackingState)
    }
  }
  private var cameraPosition: AVCaptureDevice.Position = .back
  private var imageContainerViewSize: CGSize
  private var imageContainerViewContentMode: AVLayerVideoGravity
  
  private var imageSize: CGSize = .zero
  private var image: UIImage?
  
  private var objectTrackingStartBoundingBox: CGRect?
  
  private var deviceOrientation: UIDeviceOrientation
  private var statusBarOrientation: UIInterfaceOrientation
  
  init(imageContainerViewSize: CGSize,
       imageContainerViewContentMode: AVLayerVideoGravity,
       trackingType: TrackingType,
       deviceOrientation: UIDeviceOrientation,
       statusBarOrientation: UIInterfaceOrientation) {
    self.imageContainerViewSize = imageContainerViewSize
    self.imageContainerViewContentMode = imageContainerViewContentMode
    self.trackingType = trackingType
    self.deviceOrientation = deviceOrientation
    self.statusBarOrientation = statusBarOrientation
  }
  
  func imageContainerViewSizeChanged(_ size: CGSize) {
    self.imageContainerViewSize = size
  }
  
  func trackingTypeOptionChanged(_ trackingType: TrackingType) {
    stopTracking()
    self.trackingType = trackingType
  }
  
  func trackingSensitivityOptionChanges(_ trackingSensitivity: TrackingSensitivity) {
    stopTracking()
    self.trackingSensitivity = trackingSensitivity
  }
  
  func cameraPositionChanged(_ position: AVCaptureDevice.Position) {
    stopTracking()
    self.cameraPosition = position
  }
  
  func orientationChanged(deviceOrientation: UIDeviceOrientation,
                          statusBarOrientation: UIInterfaceOrientation) {
    
    // Note that UIInterfaceOrientationLandscapeLeft is equal to UIDeviceOrientationLandscapeRight (and vice versa).
    // This is because rotating the device to the left requires rotating the content to the right.
    
    // If device orientation.rawValue == statusBarOrientation.rawValue => Rotation unlock
    // If device orientation.rawValue != statusBarOrientation.rawValue => Rotation lock
    self.deviceOrientation = deviceOrientation
    self.statusBarOrientation = statusBarOrientation
  }
  
  func startDrawingBoundingBox() {
    trackingState = .stopped
  }
  
  func setBoundingBox(_ bbox: CGRect) {
    self.objectTrackingStartBoundingBox = bbox
    self.trackingState = .started
  }
  
  func handleStartButtonClicked() {
    switch trackingState {
    case .prepare:
      trackingState = .started
    case .started:
      trackingState = .prepare
    case .updating:
      trackingState = .stopped
    case .stopped:
      trackingState = .started
    }
  }
  
  func handleNewImageSampleBuffer(sampleBuffer: CMSampleBuffer) {
    switch trackingState {
    case .started:
      guard let image = ImageHelper.image(from: sampleBuffer) else { return }
      self.image = image
      imageSize = image.size
      startTracking(image: image, boundingBox: objectTrackingStartBoundingBox)
      print(imageSize)
    case .updating:
      guard let image = ImageHelper.image(from: sampleBuffer) else { return }
      self.image = image
      imageSize = image.size
      updateTracking(image: image)
    case .stopped:
      stopTracking()
    default:
      break
    }
  }
  
  private func startTracking(image: UIImage, boundingBox: CGRect?) {
    let imageSize = image.size
    let image = getImageBasedOnOrientation(image: image)
    
    switch trackingType {
    case .human:
      do {
        try pivoSDK.startHumanTracking(image: image, trackingSensitivity: trackingSensitivity, delegate: self)
        trackingState = .updating
      }
      catch {
        trackingState = .prepare
      }
    case .horse:
      do {
        try pivoSDK.startHorseTracking(image: image, trackingSensitivity: trackingSensitivity, delegate: self)
        trackingState = .updating
      }
      catch {
        trackingState = .prepare
      }
    case .object:
      guard let boundingBox = boundingBox else {
        trackingState = .prepare
        return
      }
      
      let bboxInImageCoordinate = CoordinatorHelper.convertImageViewCoordinateToImageCoordinate(imageContainerViewSize: imageContainerViewSize, imageContainerViewContentMode: imageContainerViewContentMode, imageSize: self.imageSize, rectToConvert: boundingBox)
      
      let bbox = self.mirrorRectInCaseOfFrontCamera(bboxInImageCoordinate)
      let convertedBBox = getBoundingBoxBasedOnOrientation(imageSize: imageSize, bbox: bbox)
      do {
        try self.pivoSDK.startObjectTracking(image: image, boundingBox: convertedBBox, trackingSensitivity: trackingSensitivity, delegate: self)
        self.trackingState = .updating
      }
      catch {
        trackingState = .prepare
      }
    }
  }
  
  private func updateTracking(image: UIImage) {
    let image = getImageBasedOnOrientation(image: image)
    pivoSDK.updateTracking(image: image)
  }
  
  func stopTracking() {
    pivoSDK.stopTracking()
    trackingState = .prepare
  }
  
}

extension TrackingViewModel: TrackerDelegate {
  func tracker(didDetected targets: [Target]) {
    handleTrackingOutput(targets: targets)
  }
  
  private func handleTrackingOutput(targets: [Target]) {
    
    var targetsInViewCoordinate: [Target] = []
    
    for index in 0..<targets.count {
      let target = targets[index]
      
      let convertedRect = convertTargetBoundingBoxBasedOnOrientation(imageSize: imageSize, rect: target.boundingBox)
      let targetBBox = mirrorRectInCaseOfFrontCamera(convertedRect)
      
      // Pivo SDK return bounding box in image coordinate system, app should convert it to view system to draw the result
      let frame = CoordinatorHelper.convertImageCoordinateToImageViewCoordinate(imageContainerViewSize: imageContainerViewSize, imageContainerViewContentMode: imageContainerViewContentMode, imageSize: imageSize, rectToConvert: targetBBox)
      
      targetsInViewCoordinate.append(Target(boundingBox: frame, isTracking: target.isTracking))
    }
    delegate?.didDetected(targets: targetsInViewCoordinate)
    
  }
  
  private func mirrorRectInCaseOfFrontCamera(_ rect: CGRect) -> CGRect {
    var mirrorRect = rect
    
    switch cameraPosition {
    case .front:
      // In case of front camera, the image sent to PivoSDK is mirror image of what we actually see
      // Convert target bounding box to real bounding box
      let targetBoundingBoxMinX = mirrorRect.minX
      let targetBoundingBoxMaxX = mirrorRect.maxX
      
      let mirrorMinX = min(imageSize.width - targetBoundingBoxMinX, imageSize.width - targetBoundingBoxMaxX)
      mirrorRect = CGRect(x: mirrorMinX, y: mirrorRect.minY, width: mirrorRect.width, height: mirrorRect.height)
    default:
      break
    }
    return mirrorRect
  }
  
}

extension TrackingViewModel {
  private func getImageBasedOnOrientation(image: UIImage) -> UIImage {
    switch statusBarOrientation {
    case .portrait:
      switch deviceOrientation {
      case .portrait:
        return image
      // Device in landscape left but camera preview is not rotated (Device orientation locked)
      case .landscapeLeft:
        switch cameraPosition {
        case .back:
          if let rotatedImage = image.rotate(radians: -CGFloat.pi / 2) {
            return rotatedImage
          }
        case .front:
          if let rotatedImage = image.rotate(radians: CGFloat.pi / 2) {
            return rotatedImage
          }
        default:
          break
        }
      // Device in landscape right but camera preview is not rotated (Device orientation locked)
      case .landscapeRight:
        switch cameraPosition {
        case .back:
          if let rotatedImage = image.rotate(radians: CGFloat.pi / 2) {
            return rotatedImage
          }
        case .front:
          if let rotatedImage = image.rotate(radians: -CGFloat.pi / 2) {
            return rotatedImage
          }
        default:
          break
        }
      default:
        break
      }
    case .landscapeLeft:
      break
    case .landscapeRight:
      break
    default:
      break
    }
    
    return image
  }
  
  private func getBoundingBoxBasedOnOrientation(imageSize: CGSize, bbox: CGRect) -> CGRect {
    switch statusBarOrientation {
    case .portrait:
      switch deviceOrientation {
      case .portrait:
        break
      // Device in landscape left but camera preview is not rotated (Device orientation locked)
      case .landscapeLeft:
        switch cameraPosition {
        case .back:
          let rotatedBbox = CoordinatorHelper.rotateRectInsideImage(imageSize: imageSize, rect: bbox, rotateAngle: -CGFloat.pi / 2)
          return rotatedBbox
        case .front:
          let rotatedBbox = CoordinatorHelper.rotateRectInsideImage(imageSize: imageSize, rect: bbox, rotateAngle: CGFloat.pi / 2)
          return rotatedBbox
        default:
          break
        }
      // Device in landscape right but camera preview is not rotated (Device orientation locked)
      case .landscapeRight:
        switch cameraPosition {
        case .back:
          let rotatedBbox = CoordinatorHelper.rotateRectInsideImage(imageSize: imageSize, rect: bbox, rotateAngle: CGFloat.pi / 2)
          return rotatedBbox
        case .front:
          let rotatedBbox = CoordinatorHelper.rotateRectInsideImage(imageSize: imageSize, rect: bbox, rotateAngle: -CGFloat.pi / 2)
          return rotatedBbox
        default:
          break
        }
      default:
        break
      }
    case .landscapeLeft:
      break
    case .landscapeRight:
      break
    default:
      break
    }
    
    return bbox
  }
  
  private func convertTargetBoundingBoxBasedOnOrientation(imageSize: CGSize, rect: CGRect) -> CGRect {
    switch statusBarOrientation {
    case .portrait:
      switch deviceOrientation {
      case .portrait:
        break
      // Device in landscape left but camera preview is not rotated (Device orientation locked)
      case .landscapeLeft:
        switch cameraPosition {
        case .back:
          let size = CGSize(width: imageSize.height, height: imageSize.width)
          let convertedRect = CoordinatorHelper.rotateRectInsideImage(imageSize: size, rect: rect, rotateAngle: CGFloat.pi / 2)
          return convertedRect
        case .front:
          let size = CGSize(width: imageSize.height, height: imageSize.width)
          let convertedRect = CoordinatorHelper.rotateRectInsideImage(imageSize: size, rect: rect, rotateAngle: -CGFloat.pi / 2)
          return convertedRect
        default:
          break
        }
      // Device in landscape right but camera preview is not rotated (Device orientation locked)
      case .landscapeRight:
        switch cameraPosition {
        case .back:
          let size = CGSize(width: imageSize.height, height: imageSize.width)
          let convertedRect = CoordinatorHelper.rotateRectInsideImage(imageSize: size, rect: rect, rotateAngle: -CGFloat.pi / 2)
          return convertedRect
        case .front:
          let size = CGSize(width: imageSize.height, height: imageSize.width)
          let convertedRect = CoordinatorHelper.rotateRectInsideImage(imageSize: size, rect: rect, rotateAngle: CGFloat.pi / 2)
          return convertedRect
        default:
          break
        }
      default:
        break
      }
    case .landscapeLeft:
      break
    case .landscapeRight:
      break
    default:
      break
    }
    
    return rect
  }
}
