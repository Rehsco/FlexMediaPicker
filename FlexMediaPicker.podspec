Pod::Spec.new do |s|
  s.name             = 'FlexMediaPicker'
  s.version          = '1.1.2'
  s.license          = 'MIT'
  s.summary          = 'Image'
  s.homepage         = 'https://github.com/Rehsco/FlexMediaPicker.git'
  s.authors          = { 'Martin Jacob Rehder' => 'gitrepocon01@rehsco.com' }
  s.source           = { :git => 'https://github.com/Rehsco/FlexMediaPicker.git', :tag => s.version }
  s.ios.deployment_target = '10.0'

  s.dependency 'DynamicColor'
  s.dependency 'StyledLabel'
  s.dependency 'ImagePersistence'
  s.dependency 'MJRFlexStyleComponents'
  s.dependency 'DateToolsSwift'
  s.dependency 'StyledOverlay'
  s.dependency 'ImageSlideshow'
  s.dependency 'TaskQueue'
  s.dependency 'Player', '~> 0.7.0' ## Swift 4: 0.8.0+
  s.dependency 'SwiftSiriWaveformView', '2.1'
  s.dependency 'SCLAlertView', '0.7.0'
  s.dependency 'DSWaveformImage', '~> 5.0'

  s.platform     = :ios, '10.0'
  s.framework    = 'UIKit'
  s.source_files = 'FlexMediaPicker/**/*.swift'
  s.resources    = 'FlexMediaPicker/**/*.xcassets'
  s.requires_arc = true
end
