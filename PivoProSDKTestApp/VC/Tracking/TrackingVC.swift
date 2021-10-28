//
//  TrackingVC.swift
//  PivoProSDKTestApp
//
//  Created by Tuan on 2020/04/14.
//  Copyright © 2020 3i. All rights reserved.
//

import UIKit
import AVFoundation
import PivoProSDK

class TrackingVC: UIViewController {
  
  static func storyboardInstance() -> TrackingVC? {
    let storyboard = UIStoryboard(name: String(describing: TrackingVC.self), bundle: nil)
    return storyboard.instantiateInitialViewController() as? TrackingVC
  }
  
  @IBOutlet weak var cameraPreview: UIView!
  @IBOutlet weak var buttonTrackingState: UIButton!
  @IBOutlet weak var targetSelectionView: TargetSelectionView!
  @IBOutlet weak var segmentTrackingTypeSelection: UISegmentedControl!
  @IBOutlet weak var segmentTrackingSensitivitySelection: UISegmentedControl!
  @IBOutlet weak var labelDrawBoudingBox: UILabel!
  
  private var cameraEngine = CameraEngine()

  private var trackingState: TrackingState = .prepare {
    didSet {
      updateTrackingStateButtonText()
    }
  }
  private var pivoSDK = PivoSDK.shared
  private var trackingType: TrackingType = .object
  
  private var trackingViews: [UIView] = []
  private var imageSize: CGSize = .zero
  private var image: UIImage?
  private var objectTrackingStartBoundingBox: CGRect?
  
  private lazy var statusBarOrientation: UIInterfaceOrientation = .portrait
  private lazy var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
  
  // This class works event if the device orientation is locked
  private lazy var deviceOrientationListener = DeviceOrientation()
  
  private var viewModel: TrackingViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    setupViews()
    setPreviewOrientation()
    if let previewLayer = cameraEngine.previewLayer {
      previewLayer.frame = cameraPreview.bounds
      cameraPreview.layer.addSublayer(previewLayer)
    }
    
    cameraEngine.delegate = self
    cameraEngine.startRunning()
    
    deviceOrientationListener.delegate = self
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateCameraPreviewFrame()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    setupViewModel()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopTracking()
  }
  
  private func stopTracking() {
    viewModel.stopTracking()
  }
  
  private func setupViewModel() {
    deviceOrientation = UIDevice.current.orientation
    statusBarOrientation = UIApplication.shared.statusBarOrientation
    viewModel = TrackingViewModel(imageContainerViewSize: self.cameraPreview.bounds.size,
                                  imageContainerViewContentMode: .resizeAspectFill,
                                  trackingType: trackingType,
                                  deviceOrientation: deviceOrientation,
                                  statusBarOrientation: statusBarOrientation)
    viewModel.delegate = self
    
    setPreviewOrientation()
  }
  
  private func setPreviewOrientation() {
    let videoOrientation = getVideoOrientation()
    
    if let connection = cameraEngine.previewLayer.connection {
      if (connection.isVideoOrientationSupported) {
        connection.videoOrientation = videoOrientation
      }
    }
    
    cameraEngine.changeOrientation(videoOrientation: videoOrientation)
  }
  
  private func getVideoOrientation() -> AVCaptureVideoOrientation {
    let orientation = statusBarOrientation
    
    switch (orientation) {
    case .portrait:
      return .portrait
    case .landscapeRight:
      return .landscapeRight
    case .landscapeLeft:
      return .landscapeLeft
    case .portraitUpsideDown:
      return .portraitUpsideDown
    default:
      return .portrait
    }
  }
  
  private func setupViews() {
    setupPanGestureForDrawingObjectTrackingTarget()
    setupSegmentControllTrackingTypeSelectionView()
    segmentTrackingSensitivitySelection.selectedSegmentIndex = 2
  }
  
  private func setupSegmentControllTrackingTypeSelectionView() {
    let supportedTrackingType = pivoSDK.getSupportedTrackingModes()
    if supportedTrackingType.count <= 1 {
      segmentTrackingTypeSelection.isHidden = true
    }
    else {
      segmentTrackingTypeSelection.isHidden = false
    }
  }
  
  private func updateCameraPreviewFrame() {
    let previewLayer = cameraEngine.previewLayer
    previewLayer?.frame = cameraPreview.bounds
  }
  
  private func setupPanGestureForDrawingObjectTrackingTarget() {
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
    targetSelectionView.addGestureRecognizer(panGesture)
  }
  
  @objc private func handlePanGestureRecognizer(_ sender: UIPanGestureRecognizer) {
    handlePanToDrawGesture(sender: sender)
  }
  
  @IBAction func didTrackingTypeOptionChanged(_ sender: UISegmentedControl) {
    let selectedIndex = sender.selectedSegmentIndex
    switch selectedIndex {
    case 0:
      self.trackingType = .object
    case 1:
      self.trackingType = .human
    case 2:
      self.trackingType = .horse
    default:
      break
    }
    viewModel.trackingTypeOptionChanged(trackingType)
  }
  
  @IBAction func didTrackingSensitivityOptionChanged(_ sender: UISegmentedControl) {
    let selectedIndex = sender.selectedSegmentIndex
    var trackingSensitivity: TrackingSensitivity = .normal
    switch selectedIndex {
    case 0:
      trackingSensitivity = .off
    case 1:
      trackingSensitivity = .slow
    case 2:
      trackingSensitivity = .normal
    default:
      break
    }
    
    viewModel.trackingSensitivityOptionChanges(trackingSensitivity)
  }
  
  @IBAction func didFlipCameraButtonClicked(_ sender: Any) {
    cameraEngine.switchCamera {
      self.viewModel.cameraPositionChanged(self.cameraEngine.cameraPosition)
      self.setPreviewOrientation()
    }
  }
  
  @IBAction func didStartTrackingButtonClicked(_ sender: Any) {
    viewModel.handleStartButtonClicked()
  }
  
  private func updateTrackingStateButtonText() {
    DispatchQueue.main.async {
      switch self.trackingState {
      case .prepare, .stopped:
        self.buttonTrackingState.setTitle("Start Tracking", for: .normal)
      case .started, .updating:
        self.buttonTrackingState.setTitle("Stop Tracking", for: .normal)
      }
      
      if self.trackingType == .object && self.trackingState == .prepare {
        self.labelDrawBoudingBox.isHidden = false
      }
      else {
        self.labelDrawBoudingBox.isHidden = true
      }
    }
  }
}

extension TrackingVC: DeviceOrientationDelegate {
  func didDeviceOrientationChanged(deviceOrientation: UIDeviceOrientation, statusBarOrientation: UIInterfaceOrientation) {
    self.deviceOrientation = deviceOrientation
    self.statusBarOrientation = statusBarOrientation
    self.viewModel?.orientationChanged(deviceOrientation: deviceOrientation,
                                       statusBarOrientation: statusBarOrientation)
    
    self.setPreviewOrientation()
    
    DispatchQueue.main.async {
      let frame = self.cameraPreview.bounds.size
      self.viewModel?.imageContainerViewSizeChanged(frame)
    }
  }
}

extension TrackingVC: TrackingViewModelDelegate {
  func trackingStateChanged(_ state: TrackingState) {
    self.trackingState = state
    
    switch state {
    case .stopped, .prepare:
      removeAllTrackingViews()
    default:
      break
    }
  }
  
  func didDetected(targets: [Target]) {
    DispatchQueue.main.async { [weak self] in
      guard let strongSelf = self else { return }
      guard targets.count > 0 else {
        strongSelf.removeAllTrackingViews()
        return
      }
      
      strongSelf.prepareFaceViews(targets: targets)
      
      for index in 0..<targets.count {
        let target = targets[index]
        let trackingView = strongSelf.trackingViews[index]
        trackingView.frame = target.boundingBox
      }
    }
  }
}

extension TrackingVC: CameraEngineDelegate {
  func cameraEngineDelegate(_ cameraEngine: CameraEngine, didOutput sampleBuffer: CMSampleBuffer) {
    viewModel?.handleNewImageSampleBuffer(sampleBuffer: sampleBuffer)
  }
}

extension TrackingVC {
  private func prepareFaceViews(targets: [Target]) {
    // Find the different int the number of views and targets
    let diff = targets.count - trackingViews.count
    
    guard diff > 0 else {
      // Remove redundant view
      for _ in 0..<abs(diff) {
        let lastIndex = trackingViews.count - 1
        trackingViews[lastIndex].removeFromSuperview()
        trackingViews.remove(at: lastIndex)
      }
      return
    }
    
    // Add more views
    for _ in 0..<diff {
      addTrackingView()
    }
  }
  
  private func addTrackingView() {
    let trackingView                = UIView(frame: CGRect.zero)
    trackingView.backgroundColor    = UIColor.clear
    trackingView.layer.borderColor  = UIColor(red: 236 / 255, green: 37 / 255, blue: 68 / 255, alpha: 1).cgColor
    trackingView.layer.borderWidth  = 3.0
    trackingView.sizeToFit()
    cameraPreview.addSubview(trackingView)
    trackingViews.append(trackingView)
  }
  
  private func removeAllTrackingViews() {
    DispatchQueue.main.async { [weak self] in
      self?.trackingViews.forEach {
        $0.removeFromSuperview()
      }
      self?.trackingViews.removeAll()
    }
  }
}

extension TrackingVC {
  func handlePanToDrawGesture(sender gestureRecognizer: UIPanGestureRecognizer) {
    guard trackingType == .object else { return }
    switch gestureRecognizer.state {
    case .began:
      // Initiate object selection
      viewModel.startDrawingBoundingBox()
      let locationInView = gestureRecognizer.location(in: targetSelectionView)
      targetSelectionView.rubberbandingStart = locationInView // start new rubberbanding
    case .changed:
      // Process resizing of the object's bounding box
      let translation = gestureRecognizer.translation(in: targetSelectionView)
      targetSelectionView.rubberbandingVector = translation
      targetSelectionView.setNeedsDisplay()
    case .ended:
      // Finish resizing of the object's boundong box
      removeAllTrackingViews()
      objectTrackingStartBoundingBox = targetSelectionView.rubberbandingRect
      viewModel.setBoundingBox(targetSelectionView.rubberbandingRect)
      hideTargetSelectionView()
    default:
      break
    }
  }
  
  private func hideTargetSelectionView() {
    targetSelectionView.rubberbandingStart = CGPoint.zero
    targetSelectionView.rubberbandingVector = CGPoint.zero
    targetSelectionView.setNeedsDisplay()
  }
}
