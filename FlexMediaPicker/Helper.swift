/**
 Based on Helper.swift from MIT Licensed ImagePicker from hyperoslo
 */

import UIKit
import AVFoundation
import StyledLabel

class Helper {
    
    static func ensureOnAsyncMainThread(_ execute: @escaping (()->Void)) {
        if Thread.isMainThread {
            execute()
        }
        else {
            DispatchQueue.main.async {
                execute()
            }
        }
    }
    
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
        if minutes == 0 && hours == 0 {
            return NSString(format: "%0.2ds",seconds) as String
        }
        else if hours == 0 {
            return NSString(format: "%0.2d:%0.2d",minutes,seconds) as String
        }
        else {
            return NSString(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds) as String
        }
    }

    static func getMaskRect(inRect rect: CGRect) -> CGRect {
        switch FlexMediaPickerConfiguration.imageMaskFitting {
        case .scaleToFill:
            return CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        default:
            return CGRectHelper.AspectFitRectInRect(CGRect(x: 0, y: 0, width: 1, height: 1), rtarget: rect)
        }
    }
    
    static func getWarningLabel(withText text: String, iconSize: Int = 18) -> NSAttributedString {
        let baseText = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.warningLabelFont, color: FlexMediaPickerConfiguration.warningLabelTextColor, text: text)
        if let warnIcon = Helper.getWarningIcon(size: iconSize) {
            let iconText = Helper.imageToAttachmentImage(warnIcon, fontSize: FlexMediaPickerConfiguration.warningLabelFont.pointSize)
            let tvt = NSMutableAttributedString(attributedString: iconText)
            tvt.append(NSAttributedString(string: " "))
            tvt.append(baseText)
            return tvt
        }
        else {
            return baseText
        }
    }
    
    static func getWarningIcon(size: Int = 18) -> UIImage? {
        return UIImage(named: "warnIcon_\(size)pt", in: Bundle(for: Helper.self), compatibleWith: nil)?.tint(FlexMediaPickerConfiguration.warningIconTintColor)
    }
    
    static func getAcceptedAssetCountIcon(acceptableAssetCount: Int) -> UIImage? {
        /*
         let roundedrect = UIBezierPath()
         roundedrect.move(to: CGPoint(x: 492, y: 93))
         //                roundedrect.addCurve(to: CGPoint(x: 422, y: 184), controlPoint1: CGPoint(x: 481, y: 93), controlPoint2: CGPoint(x: 422, y: 157))
         //                roundedrect.addCurve(to: CGPoint(x: 492, y: 274), controlPoint1: CGPoint(x: 422, y: 210), controlPoint2: CGPoint(x: 481, y: 274))
         roundedrect.addLine(to: CGPoint(x: 422, y: 184))
         roundedrect.addLine(to: CGPoint(x: 492, y: 274))
         roundedrect.addLine(to: CGPoint(x: 659, y: 274))
         roundedrect.addCurve(to: CGPoint(x: 679, y: 254), controlPoint1: CGPoint(x: 670, y: 274), controlPoint2: CGPoint(x: 679, y: 265))
         roundedrect.addLine(to: CGPoint(x: 679, y: 113))
         roundedrect.addCurve(to: CGPoint(x: 659, y: 93), controlPoint1: CGPoint(x: 679, y: 102), controlPoint2: CGPoint(x: 670, y: 93))
         roundedrect.close()
         
         
         let mask = StyledShapeLayer.createShape(.custom(path: roundedrect), bounds: CGRect(x: 0, y: 0, width: 36, height: 24), color: .black)
         */
        
        let mask = StyledShapeLayer.createShape(.rounded, bounds: CGRect(x: 0, y: 0, width: 36, height: 24), color: .black)
        let nImage = UIImage(color: FlexMediaPickerConfiguration.selectedItemColor, size: CGSize(width: 36, height: 24))
        let numImage = nImage?.addText(drawText: "\(acceptableAssetCount)", font: FlexMediaPickerConfiguration.selectedMediaNumberFont)
        let maskPath = UIBezierPath(cgPath: mask.path!)
        let roundedImage = numImage?.maskImageWithPathAndCrop(maskPath)
        if let acceptImage = UIImage(named: "Accept_24pt")?.tint(FlexMediaPickerConfiguration.iconsColor) {
            return roundedImage?.appendImage(acceptImage, margin: FlexMediaPickerConfiguration.selectedMediaAcceptedCountImageMargin)
        }
        return nil
    }
    
    static func imageToAttachmentImage(_ image: UIImage, fontSize: CGFloat = 0) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image
        if fontSize > 0 {
            let dy = fontSize - image.size.height
            attachment.bounds = CGRect(x: 0, y: dy, width: image.size.width, height: image.size.height)
        }
        return NSAttributedString(attachment: attachment)
    }

}
