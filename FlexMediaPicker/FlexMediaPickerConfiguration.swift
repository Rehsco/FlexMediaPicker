/**
 Based on Configuration.swift from MIT Licensed ImagePicker from hyperoslo
 */

import UIKit
import MJRFlexStyleComponents

public class FlexMediaPickerConfiguration {
    
    // MARK: Colors
    
    public static var styleColor = UIColor(red: 0.15, green: 0.19, blue: 0.24, alpha: 1)
    public static var selectedAssetsStyleColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 0.7)
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

    public static var takeButtonColor = UIColor(white: 0.95, alpha: 1.0)
    public static var takeButtonRecordingColor = UIColor(red: 0.95, green: 0.19, blue: 0.14, alpha: 1)
    public static var takeButtonBorderColor = UIColor(white: 0.75, alpha: 1.0)

    public static var footerPanelColor = UIColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 0.85)

    public static var camVidSwitchThumbColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)
    public static var camVidSwitchBorderColor = UIColor(red: 0.25, green: 0.29, blue: 0.34, alpha: 1)

    // MARK: Styled
    
    public static var camVidSwitchStyle = FlexShapeStyle(style: .rounded)
    
    // MARK: Fonts
    
    public static var headerFont = UIFont.systemFont(ofSize: 19, weight: UIFontWeightMedium)
    public static var headerSubCaptionFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)
    public static var collectionCaptionFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)
    public static var numberLabelFont = UIFont.systemFont(ofSize: 19, weight: UIFontWeightBold)
    public static var doneButton = UIFont.systemFont(ofSize: 19, weight: UIFontWeightMedium)
    public static var flashButton = UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium)
    public static var noImagesFont = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)
    public static var noCameraFont = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)
    public static var settingsFont = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
    
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
    
    public static var cellSpacing: CGFloat = 2
    public static var indicatorWidth: CGFloat = 41
    public static var indicatorHeight: CGFloat = 8
    public static var headerHeight: CGFloat = 44
    public static var takeButtonBorderWidth: CGFloat = 8
    public static var camVidSwitchBorderWidth: CGFloat = 1.5
    
    // MARK: Custom behaviour
    
    public static var canRotateCamera = true
    public static var collapseCollectionViewWhileShot = true
    public static var recordLocation = true
    public static var allowMultipleSelection = true
    public static var allowVideoSelection = false
    public static var showsImageCountLabel = true
    public static var flashButtonAlwaysHidden = false
    public static var managesAudioSession = true
    public static var allowPinchToZoom = true
    public static var storeTakenImagesToPhotos = false
    public static var storeRecordedVideosToAssetLibrary = true

    // MARK: Limits

    /// 0 means unlimited numbers allowed, when allowMultipleSelection = true
    public static var numberItemsAllowed = 0

    
    public init() {}
}
