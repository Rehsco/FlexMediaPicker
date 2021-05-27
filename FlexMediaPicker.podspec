Pod::Spec.new do |s|
  s.name             = 'FlexMediaPicker'
  s.version          = '5.3.1'
  s.license          = 'MIT'
  s.summary          = 'Image'
  s.homepage         = 'https://github.com/Rehsco/FlexMediaPicker.git'
  s.authors          = { 'Martin Jacob Rehder' => 'gitrepocon01@rehsco.com' }
  s.source           = { :git => 'https://github.com/Rehsco/FlexMediaPicker.git', :tag => s.version }
  s.swift_version    = '5.0'
  s.ios.deployment_target = '12.1'

  s.dependency 'ImagePersistence'
  s.dependency 'DateToolsSwift'
  s.dependency 'StyledOverlay'
  s.dependency 'ImageSlideshow'
  s.dependency 'TaskQueue'
  s.dependency 'Player'
  s.dependency 'DSWaveformImage'
  s.dependency 'FlexImageCropView'

  s.platform     = :ios, '12.1'
  s.framework    = 'UIKit'
  s.source_files = 'FlexMediaPicker/**/*.swift'
  s.resources    = 'FlexMediaPicker/**/*.xcassets'
  s.requires_arc = true
end
