//
//  SelectPivoVC.swift
//
//
//  Created by Tuan on 2020/02/21.
//  Copyright © 2020 3i. All rights reserved.
//

import UIKit
import PivoProSDK

class SelectPivoVC: UIViewController, UIImagePickerControllerDelegate {
  
  static func storyboardInstance() -> UINavigationController? {
    let storyboard = UIStoryboard(name: String(describing: SelectPivoVC.self),
                                  bundle: nil)
    return storyboard.instantiateInitialViewController() as? UINavigationController
  }
  
  @IBOutlet weak var labelCenterYConstraint: NSLayoutConstraint!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var scanBarButton: UIBarButtonItem!
  @IBOutlet weak var deviceStatusLabel: UILabel!
  
  private let tableRowHeight = 75
  
  private var pivoSDK = PivoSDK.shared
  private var rotators: [BluetoothDevice] = []
  
  private var isScanning = false
  private var isConnecting = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupTableView()
    tableViewHeightConstraint.constant = 0
    labelCenterYConstraint.constant = 0
  }
  
  private func setupTableView() {
    tableView.dataSource = self
    tableView.delegate = self
    tableView.tableFooterView = UIView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    pivoSDK.disconnect()
    pivoSDK.addDelegate(self)
    tableView.reloadData()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    pivoSDK.stopScan()
    isScanning = false
    scanBarButton.title = "Scan"
    pivoSDK.removeDelegate(self)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    guard !pivoSDK.isPivoConnected() else {
      // Already connected
      handleRotatorConnected()
      return
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.startScan()
    }
  }
  
  private func startScan() {
    self.deviceStatusLabel.text = ""
    self.scanBluetoothDevice()
  }
  
  @IBAction func scanForBluetooth(_ sender: UIBarButtonItem) {
    scanBluetoothDevice()
  }
  
  func scanBluetoothDevice() {
    guard !isScanning else {
      stopScan()
      return
    }
    
    isConnecting = false
    self.rotators.removeAll()
    
    updateView()
    do {
      try pivoSDK.scan()
    }
    catch (let error as PivoError) {
      switch error {
      case .licenseNotProvided:
        presentAlert(title: "Failed", message: "License not provided")
      case .invalidLicenseKey:
        presentAlert(title: "Failed", message: "Invalid license key")
      case .expiredLicenseKey:
        presentAlert(title: "Failed", message: "License is expired")
      case .bluetoothOff:
        presentAlert(title: "Failed", message: "Bluetooth is off, please turn it on")
      case .cannotReadLicenseKeyFile:
        presentAlert(title: "Failed", message: "Can't read license key")
      case .trackingModeNotSupported:
        break
      case .bluetoothPermissionNotAllowed:
        presentAlert(title: "Failed", message: "Bluetooth premission denied")
      case .feedbackNotSupported:
        break
      case .pivoNotConnected:
        presentAlert(title: "Failed", message: "Pivo not connected")
      case .savingLocationCantBeEmpty:
        break
      }
      return
    }
    catch {
      return
    }
    
    scanBarButton.title = "Stop"
    isScanning = true
    
    deviceStatusLabel.text = "Scanning..."
    
    let scanningPeriod : DispatchTime = .now() + 5
    
    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: scanningPeriod, execute: {
      DispatchQueue.main.async { () in
        if self.isScanning {
          self.stopScan()
        }
      }
    })
  }
  
  private func stopScan() {
    pivoSDK.stopScan()
    isScanning = false
    scanBarButton.title = "Scan"
    handleAfterScanning()
  }
  
  private func presentAlert(title: String?, message: String?) {
    let alertController = UIAlertController(title: title,
                                            message: message,
                                            preferredStyle: UIAlertController.Style.alert)
    
    let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
    alertController.addAction(okAction)
    present(alertController, animated: true, completion: nil)
  }
  
  private func handleAfterScanning() {
    //MARK: + If 1 device is availabel => connect
    //      + Multiple devices ask user for selecting
    if self.rotators.count == 0 {
      self.deviceStatusLabel.text = "Could not find any rotator"
    } else if self.rotators.count == 1 {
      self.deviceStatusLabel.text = "Please connect to rotator"
      self.isConnecting = true
      self.pivoSDK.connect(device: self.rotators.first!)
    } else {
      self.deviceStatusLabel.text = "Several rotator detected"
    }
  }
  
  func updateView() {
    DispatchQueue.main.async {
      UIView.animate(withDuration: 0.1) {
        self.tableViewHeightConstraint.constant = CGFloat(self.rotators.count * self.tableRowHeight)
        self.labelCenterYConstraint.constant = -CGFloat(self.rotators.count * self.tableRowHeight) / 2
      }
    }
  }
}

extension SelectPivoVC: PodConnectionDelegate {
  func pivoConnection(didDiscover device: BluetoothDevice) {
    self.rotators.append(device)
    updateView()
    DispatchQueue.main.async { [weak self] in
      self?.tableView.reloadData()
    }
  }
  
  func pivoConnection(didEstablishSuccessfully device: BluetoothDevice) {
    isConnecting = false
    DispatchQueue.main.async { [weak self] in
      self?.tableView.reloadData()
      self?.handleRotatorConnected()
      self?.view.isUserInteractionEnabled = true
    }
  }
  
  func pivoConnectionBluetoothPermissionDenied() {
    stopScan()
    presentAlert(title: "Failed", message: "Bluetooth premission denied")
  }
  
  func pivoConnection(didFailToConnect device: BluetoothDevice) {
    isConnecting = false
    DispatchQueue.main.async { [weak self] in
      self?.view.isUserInteractionEnabled = true
      let alertController = UIAlertController(title: "Connection Failed",
                                              message: "Failed to connect. Do you want to try again?",
                                              preferredStyle: UIAlertController.Style.alert)
      
      let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
      let scanAction = UIAlertAction(title: "Scan", style: UIAlertAction.Style.default) { (result : UIAlertAction) -> Void in
        self?.rotators.removeAll()
        self?.updateView()
        self?.scanBluetoothDevice()
      }
      
      alertController.addAction(cancelAction)
      alertController.addAction(scanAction)
      self?.present(alertController, animated: true, completion: nil)
    }
  }
  
  private func handleRotatorConnected() {
    // Open next view
    if let vc = ControlPivoVC.storyboardInstance() {
      DispatchQueue.main.async {
        self.navigationController?.pushViewController(vc, animated: true)
      }
    }
  }
}

extension SelectPivoVC : UITableViewDataSource, UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.rotators.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let currentPer = self.rotators[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "SelectDeviceCellID", for: indexPath) as! BluetoothDeviceTableViewCell
    
    // Cell Layout
    cell.deviceNameLabel.adjustsFontSizeToFitWidth = true
    cell.deviceIDLabel.adjustsFontSizeToFitWidth = true
    cell.deviceNameLabel.text = currentPer.name
    cell.deviceIDLabel.text = "Device ID"
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let currentPer = self.rotators[indexPath.row]
    
    self.view.isUserInteractionEnabled = false
    
    tableView.deselectRow(at: indexPath, animated: false)
    if !self.isConnecting {
      self.pivoSDK.connect(device: currentPer)
    }
  }
}

class BluetoothDeviceTableViewCell: UITableViewCell {
  
  //MARK: IBOutlet Properties
  @IBOutlet var deviceIDLabel: UILabel!
  @IBOutlet var deviceNameLabel: UILabel!
}
