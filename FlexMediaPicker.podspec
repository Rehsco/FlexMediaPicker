Pod::Spec.new do |s|
  s.name             = 'FlexMediaPicker'
  s.version          = '1.0'
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

  s.platform     = :ios, '10.0'
  s.framework    = 'UIKit'
  s.source_files = 'FlexMediaPicker/**/*.swift'
  s.resources    = 'FlexMediaPicker/**/*.xcassets'
  s.requires_arc = true
end
