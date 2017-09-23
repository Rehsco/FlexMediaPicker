Pod::Spec.new do |s|
  s.name             = 'FlexImagePicker'
  s.version          = '1.0'
  s.license          = 'MIT'
  s.summary          = 'Image'
  s.homepage         = 'https://github.com/mjrehder/MJRFlexStyleComponents.git'
  s.authors          = { 'Martin Jacob Rehder' => 'gitrepocon01@rehsco.com' }
  s.source           = { :git => 'https://github.com/mjrehder/MJRFlexStyleComponents.git', :tag => s.version }
  s.ios.deployment_target = '10.0'

  s.dependency 'DynamicColor'
  s.dependency 'StyledLabel'

  s.framework    = 'UIKit'
  s.source_files = 'MJRFlexStyleComponents/*.swift'
  s.requires_arc = true
end
