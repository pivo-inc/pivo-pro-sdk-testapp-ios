//
//  CameraController.swift
//  PivoProSDKTestApp
//
//  Created by Tuan on 2020/04/14.
//  Copyright © 2020 3i. All rights reserved.
//

import AVFoundation
import UIKit
import Photos

protocol CameraEngineDelegate {
  func cameraEngineDelegate(_ cameraEngine: CameraEngine, didOutput sampleBuffer: CMSampleBuffer)
}

class CameraEngine: NSObject {
  
  var previewLayer: AVCaptureVideoPreviewLayer!
  var delegate: CameraEngineDelegate?
  var cameraPosition: AVCaptureDevice.Position = .back
  
  private var session: AVCaptureSession!
  private let sessionQueue = DispatchQueue(label: "session queue")
  
  private var videoDataOutput: AVCaptureVideoDataOutput!
  private var frontCamera: AVCaptureDevice!
  private var backCamera: AVCaptureDevice!
  private var videoDeviceInput: AVCaptureDeviceInput!
  
  override init() {
    super.init()
    initializeSession()
  }
  
  private func initializeSession() {
    session = AVCaptureSession()
    session.beginConfiguration()
    session.sessionPreset = .high
    
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = .resizeAspectFill
    
    configureSession()
    session.commitConfiguration()
  }
  
  private func configureSession() {
    configureBackCameraDeviceInput()
    configureCaptureVideoDataOutput()
    
    //configureFrontCameraDeviceInput()
  }
  
  private func configureBackCameraDeviceInput() {
    backCamera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first
    
    guard let backCamera = backCamera else {
      return
    }
    
    if let cameraDeviceInput = try? AVCaptureDeviceInput(device: backCamera) {
      if self.session.canAddInput(cameraDeviceInput) {
        self.session.addInput(cameraDeviceInput)
        self.videoDeviceInput = cameraDeviceInput
      }
    }
    
    if let connection = self.videoDataOutput?.connection(with: AVMediaType.video) {
      connection.videoOrientation = .portrait
    }
  }
  
  private func configureFrontCameraDeviceInput() {
    frontCamera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices.first
    
    guard let frontCamera = frontCamera else {
      return
    }
    
    if let cameraDeviceInput = try? AVCaptureDeviceInput(device: frontCamera) {
      if self.session.canAddInput(cameraDeviceInput) {
        self.session.addInput(cameraDeviceInput)
        self.videoDeviceInput = cameraDeviceInput
      }
    }
    
    if let connection = self.videoDataOutput?.connection(with: AVMediaType.video) {
      connection.videoOrientation = .portrait
    }
  }
  
  private func configureCaptureVideoDataOutput() {
    videoDataOutput = AVCaptureVideoDataOutput()
    videoDataOutput.alwaysDiscardsLateVideoFrames = true
    
    let videoDataOutputQueue = DispatchQueue(label: "app.pivo.camera.videoDataOutputQueue")
    videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    
    guard self.session.canAddOutput(videoDataOutput) else { return }
    self.session.addOutput(videoDataOutput)
    
    if let connection = self.videoDataOutput.connection(with: AVMediaType.video) {
      connection.videoOrientation = .portrait
    }
  }
  
  func startRunning() {
    session.startRunning()
  }
  
  func stopRunning() {
    session.stopRunning()
  }
  
  func changeOrientation(videoOrientation: AVCaptureVideoOrientation) {
    if let connection = self.videoDataOutput.connection(with: AVMediaType.video) {
      connection.videoOrientation = videoOrientation
    }
  }
  
  func switchCamera(completion: @escaping ()->()) {
    sessionQueue.async {
      let currentVideoDevice = self.videoDeviceInput.device
      let currentPosition = currentVideoDevice.position
      
      switch currentPosition {
      case .unspecified, .front:
        self.session.beginConfiguration()
        self.session.removeInput(self.videoDeviceInput)
        self.configureBackCameraDeviceInput()
        self.cameraPosition = .back
        self.session.commitConfiguration()
      case .back:
        self.session.beginConfiguration()
        self.session.removeInput(self.videoDeviceInput)
        self.configureFrontCameraDeviceInput()
        self.cameraPosition = .front
        self.session.commitConfiguration()
      @unknown default:
        break
      }
      completion()
    }
  }
}

extension CameraEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    delegate?.cameraEngineDelegate(self, didOutput: sampleBuffer)
  }
}
