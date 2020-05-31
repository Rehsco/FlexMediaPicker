# FlexMediaPicker
Media Picker written in Swift for selecting and taking photos, videos and audio recordings.

## Installation

### CocoaPods

Install CocoaPods if not already available:

``` bash
$ [sudo] gem install cocoapods
$ pod setup
```
Go to the directory of your Xcode project, and Create and Edit your Podfile and add _import FlexMediaPicker_:

``` bash
$ cd /path/to/MyProject
$ touch Podfile
$ edit Podfile
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, ‘11.0’

use_frameworks!
pod ‘import FlexMediaPicker’
```

Install into your project:

``` bash
$ pod install
```

Open your project in Xcode from the .xcworkspace file (not the usual project file):

``` bash
$ open MyProject.xcworkspace
```

You can now `import FlexMediaPicker` framework into your files.

## Usage

See the demo project contained in the code for a usage guide.

## License

FlexMediaPicker is available under the MIT license. See the LICENSE file for more info.
