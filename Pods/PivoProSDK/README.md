# Pivo Pro SDK

Pivo Pro SDK is an iOS Framework which can be used to:
- Connect with Pivo
- Control Pivo
- Tracking with Pivo

For more information about Pivo [getpivo.com](getpivo.com)

For more information of the SDK and contact to get license to use the SDK: https://developer.pivo.app/

Test app located at: https://github.com/pivo-inc/pivo-pro-sdk-testapp-ios

## Changelogs

In version 0.0.8:
- Change class name from `PivoProSDK` to `PivoSDK` to prevent an error
- Support new Pivo types
- Build with Swift 5.5
- In order to get `Rotated` feedback when rotates Pivo, please make sure to use `turnLeftWithFeedback` and `turnRightWithFeedback` with speed from `getSupportedSpeedsByRemoteControllerInSecoundsPerRound`

In version 0.0.9:

By Pass Remote Controller is the ability that the Pod ignores the command from remote controller. For example, if by pass is off, click rotate left button on the remote controller will result the pod rotates to the left, the app gets the feedback. If by pass is on, click rotate left button on the remote controller, the pod won't rotate but the app still gets the feedback
 
- Add functions to check whether a Pivo Pod supports By Pass Remote Controller by `isByPassRemoteControllerSupported()` function
- Add functions to turn on and turn off By Pass Remote Controller by `turnOnByPassRemoteController()` and `turnOffBypassRemoteController()` functions

In version 0.0.10:

- Build with XCode 14.0 to support iOS 16

In version 1.0.1:
- Support Pivo Max
