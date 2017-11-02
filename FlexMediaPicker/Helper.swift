/**
 Based on Helper.swift from MIT Licensed ImagePicker from hyperoslo
 */

import UIKit
import AVFoundation
import StyledLabel

struct Helper {
    
    static func rotationTransform() -> CGAffineTransform {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return CGAffineTransform(rotationAngle: CGFloat.pi * 0.5)
        case .landscapeRight:
            return CGAffineTransform(rotationAngle: -(CGFloat.pi * 0.5))
        case .portraitUpsideDown:
            return CGAffineTransform(rotationAngle: CGFloat.pi)
        default:
            return CGAffineTransform.identity
        }
    }
    
    static func videoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return .portrait
        }
    }
    
    static func screenSizeForOrientation() -> CGSize {
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            return CGSize(width: UIScreen.main.bounds.height,
                          height: UIScreen.main.bounds.width)
        default:
            return UIScreen.main.bounds.size
        }
    }
    
    static func applyFontAndColorToString(_ font: UIFont, color: UIColor, text: String) -> NSAttributedString {
        let attributedString = NSAttributedString(string: text, attributes:
            [   NSFontAttributeName : font,
                NSForegroundColorAttributeName: color
            ])
        return attributedString
    }
    
    static func stringFromTimeInterval(interval: TimeInterval) -> String {
        let ti = NSInteger(interval.isNaN ? 0 : interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        return NSString(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds) as String
    }

    static func getMaskRect(inRect rect: CGRect) -> CGRect {
        switch FlexMediaPickerConfiguration.imageMaskFitting {
        case .scaleToFill:
            return CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        default:
            return CGRectHelper.AspectFitRectInRect(CGRect(x: 0, y: 0, width: 1, height: 1), rtarget: rect)
        }
    }
}
