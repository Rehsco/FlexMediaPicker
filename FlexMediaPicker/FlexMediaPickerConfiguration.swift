/**
 Based on Configuration.swift from MIT Licensed ImagePicker from hyperoslo
 */

import UIKit
import MJRFlexStyleComponents
import AVFoundation

public class FlexMediaPickerConfiguration {
    
    // MARK: Colors
    
    public static var styleColor = UIColor(red: 0.15, green: 0.19, blue: 0.24, alpha: 1)
    public static var selectedItemColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)
    public static var gallerySeparatorColor = UIColor.black.withAlphaComponent(0.6)
    public static var headerColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1)
    public static var imagePlaceholderColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1)
    public static var collectionCaptionColor = UIColor.white
    public static var noImagesColor = UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1)
    public static var noCameraColor = UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1)
    public static var settingsColor = UIColor.white
    public static var headerTextColor = UIColor.white

    public static var iconsColor = UIColor.white
    public static var disabledIconsColor = UIColor(white: 0.6, alpha: 1.0)

    public static var selectedMediaStyleColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 0.7)
    public static var selectedMediaCaptionColor = UIColor(white: 0.85, alpha: 1.0)

    public static var centerActionButtonStyleColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)
    
    public static var takeButtonColor = UIColor(white: 0.95, alpha: 1.0)
    public static var takeButtonRecordingColor = UIColor(red: 0.95, green: 0.19, blue: 0.14, alpha: 1)
    public static var takeButtonNotRecordingColor = UIColor(white: 0.95, alpha: 1.0)
    public static var takeButtonBorderColor = UIColor(white: 0.95, alpha: 1.0)
    public static var takeButtonRingColor = UIColor(white: 0.85, alpha: 1.0)

    public static var overlayMaskColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.55)

    public static var alertStyleColor = UIColor(red: 0.15, green: 0.19, blue: 0.24, alpha: 1)
    public static var alertTitleColor = UIColor.white
    public static var alertSecondaryColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)
    public static var alertButtonColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1)

    /// When recording and switching to camera
    public static var takeButtonRecordingBorderColorWhileInCameraMode = UIColor(red: 0.95, green: 0.19, blue: 0.14, alpha: 1)
    public static var takeButtonRecordingColorWhileInCameraMode = UIColor(white: 0.95, alpha: 1.0)

    public static var footerPanelColor = UIColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 0.85)
    public static var timeSliderPanelColor = UIColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 0.85)
    public static var timeSliderThumbColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)
    public static var timeSliderSeparatorColor = UIColor(red: 0.15, green: 0.19, blue: 0.24, alpha: 1)
    public static var timeSliderBorderColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)
    public static var timeSliderCaptionTextColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)

    public static var frameStepperThumbColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)
    public static var frameStepperSeparatorColor = UIColor(red: 0.15, green: 0.19, blue: 0.24, alpha: 1)
    public static var frameStepperBorderColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)
    public static var frameStepperThumbTextColor = UIColor.white
    public static var frameStepperSeparatorTextColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)

    public static var camVidSwitchThumbColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)
    public static var camVidSwitchBorderColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)

    public static var upperProgressLabelTextColor = UIColor.white
    public static var lowerProgressLabelTextColor = UIColor.white

    public static var audioWaveformColor = UIColor(white: 0.35, alpha: 1.0)
    public static var audioWaveformHighlightColor = UIColor.white
    
    public static var warningIconTintColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
    public static var warningLabelTextColor = UIColor.white

    // MARK: Styled
    
    public static var camVidSwitchStyle = FlexShapeStyle(style: .rounded)
    public static var centerActionButtonStyle: FlexShapeStyle = FlexShapeStyle(style: .rounded)

    public static var takeButtonStyle: FlexShapeStyle = FlexShapeStyle(style: .thumb)

    public static var timeSliderStyle: FlexShapeStyle = FlexShapeStyle(style: .rounded)
    public static var timeSliderThumbStyle: FlexShapeStyle = FlexShapeStyle(style: .rounded)

    public static var frameStepperStyle: FlexShapeStyle = FlexShapeStyle(style: .rounded)
    public static var frameStepperThumbStyle: FlexShapeStyle = FlexShapeStyle(style: .rounded)

    public static var imageMaskStyle: FlexShapeStyle = FlexShapeStyle(style: .thumb)
    
    // MARK: Fonts
    
    public static var headerFont = UIFont.systemFont(ofSize: 19, weight: UIFontWeightMedium)
    public static var headerSubCaptionFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)
    public static var collectionCaptionFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)
    public static var numberLabelFont = UIFont.systemFont(ofSize: 19, weight: UIFontWeightBold)
    public static var noImagesFont = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)
    public static var noCameraFont = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)
    public static var settingsFont = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
    public static var timeSliderCaptionFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)

    public static var upperProgressLabelFont = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
    public static var lowerProgressLabelFont = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)

    public static var selectedMediaNumberFont = UIFont.systemFont(ofSize: 32, weight: UIFontWeightRegular)
    public static var selectedMediaCaptionFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)

    public static var alertTitleFont = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
    public static var alertTextFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)
    public static var alertButtonFont = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)

    public static var warningLabelFont = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)

    // MARK: Titles

    public static var mediaTitle = "Media Library"
    public static var OKButtonTitle = "OK"
    public static var cancelButtonTitle = "Cancel"
    public static var doneButtonTitle = "Done"
    public static var noImagesTitle = "No images available"
    public static var noCameraTitle = "Camera is not available"
    public static var settingsTitle = "Settings"
    public static var requestPermissionTitle = "Permission denied"
    public static var requestPermissionMessage = "Please, allow the application to access to your photo library."

    // MARK: Dimensions
    
    public static var thumbnailSize: CGSize = CGSize(width: 100, height: 100)
    public static var locationImageSize: CGSize = CGSize(width: 512, height: 512)
    public static var cellSpacing: CGFloat = 2
    public static var indicatorWidth: CGFloat = 41
    public static var indicatorHeight: CGFloat = 8
    public static var headerHeight: CGFloat = 44
    public static var footerHeight: CGFloat = 64
    public static var takeButtonRadius: CGFloat = 54
    public static var takeButtonBorderWidth: CGFloat = 8
    public static var takeButtonRingWidth: CGFloat = 1.5
    public static var camVidSwitchBorderWidth: CGFloat = 1.5
    public static var camVidSwitchSize: CGSize = CGSize(width: 80, height: 40)
    
    public static var centerActionButtonWidth: CGFloat = 80
    public static var centerActionButtonHeight: CGFloat = footerHeight * 0.8
    
    public static var timeSliderPanelHeight: CGFloat = 72
    public static var timeSliderBorderWidth: CGFloat = 1.5
    public static var timeSliderThumbSize: CGSize = CGSize(width: 25, height: 25)
    public static var timeSliderBeginEndThumbSize: CGSize = CGSize(width: 18, height: 32)
    public static var timeSliderBarInsets: UIEdgeInsets = UIEdgeInsets(top: 26, left: 0, bottom: 26, right: 0)
    public static var timeSliderCaptionPanelHeight: CGFloat = 20
    public static var timeSliderCaptionPanelInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

    public static var frameStepperBorderWidth: CGFloat = 1.5
    public static var frameStepperSize: CGSize = CGSize(width: 200, height: 40)

//    public static var imageMaskMargin: UIEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
    public static var imageCroppingMaxScale: CGFloat = 5.0
    // Currently available: scaleToFit and scaleToFill
    public static var imageMaskFitting: FlexImageShapeFit = .scaleToFit

    public static var voiceRecordingSampleImageSize = CGSize(width: 256, height: 128)
    public static var voiceRecordingUpdateMetricsInterval: TimeInterval = 0.06
    // This must be at least <voiceRecordingUpdateMetricsInterval>
    public static var voiceRecordingSamplingInterval: TimeInterval = 0.12
    
    public static var selectedMediaAcceptedCountImageMargin: CGFloat = 2
    
    // MARK: Custom behaviour
    
    public static var statusBarHidden = true

    public static var canRotateCamera = true
    public static var flashButtonAlwaysHidden = false
    public static var managesAudioSession = true

    public static var allowMultipleSelection = true
    public static var allowVideoSelection = false
    public static var allowVoiceRecording = true
    public static var allowLocationSelection = true

    public static var showsImageCountLabel = true
    public static var allowPinchToZoom = true
    public static var storeTakenImagesToPhotos = true
    public static var storeRecordedVideosToAssetLibrary = true

    public static var maskImage = true
    public static var maskImageAutoCropToDetectedFace = true

    public static var recordLocationOnPhoto = true

    // MARK: Media Formats

    public static var videoOutputFormat = AVAssetExportPreset640x480
//    public static var videoOutputFormat = AVAssetExportPresetPassthrough

    // MARK: Limits

    /// 0 means unlimited numbers allowed, when allowMultipleSelection = true
    public static var numberItemsAllowed = 0

    
    public init() {}
}
