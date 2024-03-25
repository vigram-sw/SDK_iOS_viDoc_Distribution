# VigramSDK

VigramSDK is a library to connect your app to viDoc to retrieve location data and perform laser distance recordings.

For more information, you can view the documentation using [web](https://vigram-sw.github.io/SDK_iOS_viDoc_Distribution/documentation/vigramsdk/)  or [Xcode](https://github.com/vigram-sw/SDK_iOS_viDoc_Distribution/tree/docs/VigramSDK.doccarchive)

## Installation

VigramSDK supports both Cocoapods and Swift Package Manager.

#### Cocoapods

You can integrate VigramSDK into your app by using the following line in your `Podfile`:

```ruby
pod 'Vigram', :git => 'https://github.com/vigram-sw/SDK_iOS_viDoc_Distribution.git'
```

Use the pod _**`Vigram/Rx`**_, if you would like to use VigramSDK in addition to RxSwift. The module _**`Vigram`**_ includes VigramSDK and its extensions, whereas _**`VigramSDK`**_ only contains VigramSDK itself (i.e. without the additions for RxSwift).

#### Swift Package Manager

Specify the following url:

```
https://github.com/vigram-sw/SDK_iOS_viDoc_Distribution.git
```

Make sure to add your Github account credentials to Xcode before attempting to add the package.
Use the target **`VigramSDK+Rx`** only if you would like to use VigramSDK in addition to RxSwift.
