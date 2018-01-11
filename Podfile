platform :ios, '10.0'
use_frameworks!

pod 'MJRFlexStyleComponents'
pod 'DateToolsSwift'
pod 'StyledOverlay'
pod 'ImageSlideshow'
pod 'ImagePersistence'
pod 'TaskQueue'
pod 'Player'
pod 'SwiftSiriWaveformView'
pod 'DSWaveformImage'

target 'FlexMediaPicker' do
end

target 'FlexMediaPickerExample' do
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.0'
        end
    end
end
