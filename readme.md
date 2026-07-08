# VigramSDK

v2.0.0-beta.3.

VigramSDK is a library to connect your app to viDoc to retrieve location data and perform laser distance recordings.

For more information, you can view the documentation using [web](https://vigram-sw.github.io/SDK_iOS_viDoc_Distribution/documentation/vigramsdk/) or [Xcode](https://vigram-sw.github.io/SDK_iOS_viDoc_Distribution/tutorials/viewdocs/).

## Installation

VigramSDK supports both Cocoapods and Swift Package Manager.

#### Cocoapods

You can integrate VigramSDK into your app by using the following line in your `Podfile`:

```ruby
pod 'Vigram', :git => 'https://github.com/vigram-sw/SDK_iOS_viDoc_Distribution.git', :tag => '2.0.0-beta.3'
```

Use the pod `Vigram/Rx` if you would like to use VigramSDK in addition to RxSwift.

#### Swift Package Manager

Specify the following URL and select exact version `2.0.0-beta.3`:

```
https://github.com/vigram-sw/SDK_iOS_viDoc_Distribution.git
```

Use the target `VigramSDK+Rx` only if you would like to use VigramSDK in addition to RxSwift.
