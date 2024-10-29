# Pivo Pro SDK iOS test application

An iOS application that uses PivoProSDK to connect and control the Pivo Pod.

## Before you begin

Please visit [Pivo developer website](https://developer.pivo.app/) and generate the license file to include it into your project. 

## Installation

#### CocoaPods
In your pod file, add this:

```
pod 'PivoProSDK', :git => 'https://github.com/pivo-inc/pivo-pro-sdk-ios.git', :tag => '1.0.2'
```
## Usage

In your AppDelegate.swift

```swift
//...
import PivoProSDK

class AppDelegate: UIResponder, UIApplicationDelegate {
{
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      // Override point for customization after application launch.
      
      if let licenseFileURL = Bundle.main.url(forResource: "licenseKey", withExtension: "json") {
        do {
          try PivoBasicSDK.shared.unlockWithLicenseKey(licenseKeyFileURL: licenseFileURL)
        }
        catch {
          print(error)
        }
      }
      
      return true
    }

//...
}
```

To check whick type of tracking are supported, you can call:

```swift
  let supportedTrackingType = pivoSDK.getSupportedTrackingModes()
```

Notice that Human and Face Tracking are only supported on iOS 12 and above

### Action/Object Tracking:

In order to start tracking a desired target on the screen.

First, you need to select the region on interest then
```swift
  try self.pivoSDK.startObjectTracking(image: image, boundingBox: regionOfInterest, trackingSensitivity: trackingSensitivity, delegate: self)
```

### Person/Face Tracking:

To start person or Face tracking, simply call

```swift
  try pivoSDK.startHumanTracking(image: image, trackingSensitivity: trackingSensitivity, delegate: self)
  try pivoSDK.startFaceTracking(image: image, trackingSensitivity: trackingSensitivity, delegate: self)
```

To receive tracking output information, set your class as TrackerDelegate
```swift
class YourClass: TrackerDelegate {
  func tracker(didDetected targets: [Target]) {
    // Tracking output result goes here
    
  }
}
```

## Report
If you encounter an issue during setting up the sdk, please contact us at app@3i.ai or open an issue.

## Changelogs

In version 1.0.2:
- Support Pivo Max
- Add Face Tracking

In version 0.1.0:
- Fix connection issue with pod version 9

In version 0.0.8:
- Change class name from `PivoProSDK` to `PivoSDK` to prevent an error
- Support new Pivo types
- Build with Swift 5.5
- In order to get `Rotated` feedback when rotates Pivo, please make sure to use `turnLeftWithFeedback` and `turnRightWithFeedback` with speed from `getSupportedSpeedsByRemoteControllerInSecoundsPerRound`
