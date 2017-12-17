//
//  UIImageExtensions.swift
//  MJRFlexStyleComponents
//
//  Created by Martin Rehder on 21.10.2016.
/*
 * Copyright 2016-present Martin Jacob Rehder.
 * http://www.rehsco.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import UIKit

extension UIImage {
    func tint(_ color: UIColor) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()
        
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.translateBy(x: 0, y: self.size.height)
        ctx!.scaleBy(x: 1.0, y: -1.0);
        ctx!.setBlendMode(CGBlendMode.normal)
        
        let area = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height);
        ctx!.clip(to: area, mask: self.cgImage!)
        ctx!.fill(area)
        
        defer { UIGraphicsEndImageContext() };
        
        return UIGraphicsGetImageFromCurrentImageContext()!;
    }
    
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1), scale: CGFloat = UIScreen.main.scale) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, scale)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    func circularImage(size: CGSize?) -> UIImage? {
        let newSize = size ?? self.size
        
        let minEdge = min(newSize.height, newSize.width)
        let size = CGSize(width: minEdge, height: minEdge)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        self.draw(in: CGRect(origin: CGPoint.zero, size: size), blendMode: .copy, alpha: 1.0)
        
        context!.setBlendMode(.copy)
        context!.setFillColor(UIColor.clear.cgColor)
        
        let rectPath = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: size))
        let circlePath = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: size))
        rectPath.append(circlePath)
        rectPath.usesEvenOddFillRule = true
        rectPath.fill()
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }

    func overlayImage(image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        self.draw(in: CGRect(origin: CGPoint.zero, size: size), blendMode: .copy, alpha: 1.0)
        image.draw(in: CGRect(origin: CGPoint.zero, size: size), blendMode: .normal, alpha: 1.0)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }

    func maskImage(mask: UIImage) -> UIImage? {
        if let imageReference = self.cgImage, let maskReference = mask.cgImage, let dataProvider = maskReference.dataProvider {
            if let imageMask = CGImage(maskWidth: maskReference.width,
                                    height: maskReference.height,
                                    bitsPerComponent: maskReference.bitsPerComponent,
                                    bitsPerPixel: maskReference.bitsPerPixel,
                                    bytesPerRow: maskReference.bytesPerRow,
                                    provider: dataProvider, decode: nil, shouldInterpolate: true) {
                if let maskedReference = imageReference.masking(imageMask) {
                    let maskedImage = UIImage(cgImage:maskedReference)
                    return maskedImage
                }
            }
        }
        return nil
    }
    
    func crop(toRect rect: CGRect) -> UIImage {
        if let imageRef = self.cgImage?.cropping(to: rect) {
            let cropped = UIImage(cgImage: imageRef)
            return cropped
        }
        return self
    }
    
    func resized(newSize: CGSize) -> UIImage? {
        // Guard newSize is different
        guard self.size != newSize else { return self }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func maskImageWithPathAndCrop(_ path: UIBezierPath) -> UIImage {
        let newSize = path.cgPath.boundingBox.size
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()
        
        self.draw(in: CGRect(origin: CGPoint.zero, size: newSize), blendMode: .copy, alpha: 1.0)
        
        context!.setBlendMode(.copy)
        context!.setFillColor(UIColor.clear.cgColor)
        
        let rectPath = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: newSize))
        rectPath.append(path)
        rectPath.usesEvenOddFillRule = true
        rectPath.fill()
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result!
    }

    func maskImageWithPath(_ path: UIBezierPath) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()
        
        self.draw(in: CGRect(origin: CGPoint.zero, size: self.size), blendMode: .copy, alpha: 1.0)
        
        context!.setBlendMode(.copy)
        context!.setFillColor(UIColor.clear.cgColor)
        
        let rectPath = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: self.size))
        rectPath.append(path)
        rectPath.usesEvenOddFillRule = true
        rectPath.fill()
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result!
    }

    func scaleToSizeKeepAspect(size: CGSize) -> UIImage {
        let ws = size.width/self.size.width
        let hs = size.height/self.size.height
        let scale = min( ws, hs)
        
        let srcSize = self.size
        let rect = CGRect(x: srcSize.width/2-(srcSize.width*scale)/2,
                          y: srcSize.height/2-(srcSize.height*scale)/2, width: srcSize.width*scale,
                          height: srcSize.height*scale)
        
        UIGraphicsBeginImageContext(rect.size)
        
        let context = UIGraphicsGetCurrentContext()
        context!.translateBy(x: 0.0, y: rect.size.height)
        context!.scaleBy(x: 1.0, y: -1.0)
        
        context!.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func addText(drawText text: String, textColor: UIColor = UIColor.white, font: UIFont? = nil) -> UIImage {
        let textFont = font ?? UIFont.systemFont(ofSize: 24)
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)

        self.draw(in: CGRect(origin: CGPoint.zero, size: self.size))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            NSParagraphStyleAttributeName: paragraphStyle,
            ] as [String : Any]
        
        let tHeight = text.heightWithConstrainedWidth(self.size.width, font: textFont)
        
        let rect = CGRect(origin: CGPoint(x: 0, y: (self.size.height - tHeight) * 0.5), size: CGSize(width: self.size.width, height: tHeight))
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    /// Returns a new image with this image and the given image to the right of it
    func appendImage(_ image: UIImage, margin: CGFloat = 0.0) -> UIImage {
        let newSize = CGSize(width: self.size.width + image.size.width + margin, height: max(self.size.height, image.size.height))
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        
        self.draw(at: CGPoint(x: 0, y: (newSize.height - self.size.height) * 0.5))
        image.draw(at: CGPoint(x: self.size.width + margin, y: (newSize.height - image.size.height) * 0.5))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func fixOrientation() -> UIImage {
        // No-op if the orientation is already correct.
        if (self.imageOrientation == .up) {
            return self
        }
    
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform = CGAffineTransform.identity
    
        switch self.imageOrientation {
        case .down:
            fallthrough
        case .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
            
        case .left:
            fallthrough
        case .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2.0))
            
        case .right:
            fallthrough
        case .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: -CGFloat(Double.pi / 2.0))
            
        case .up:
            fallthrough
        case .upMirrored:
            break
        }
        
        switch (self.imageOrientation) {
        case .upMirrored:
            fallthrough
        case .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored:
            fallthrough
        case .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .up:
            break
        case .down:
            break
        case .left:
            break
        case .right:
            break
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                            bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0,
                            space: self.cgImage!.colorSpace!,
                            bitmapInfo: self.cgImage!.bitmapInfo.rawValue)
        ctx!.concatenate(transform)
        switch (self.imageOrientation) {
        case .left:
            fallthrough
        case .leftMirrored:
            fallthrough
        case .right:
            fallthrough
        case .rightMirrored:
            ctx?.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width))
            
        default:
            ctx?.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        }
        
        // And now we just create a new UIImage from the drawing context.
        let cgimg = ctx!.makeImage()
        let img = UIImage(cgImage:cgimg!)
        return img
    }
    
    func rotateByAngle(angleInRadians: CGFloat) -> UIImage {
        let contextSize = size
        
        UIGraphicsBeginImageContextWithOptions(contextSize, false, self.scale)
        defer {
            UIGraphicsEndImageContext()
        }
        
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        
        context.translateBy(x: 0.5 * contextSize.width, y: 0.5 * contextSize.height)
        context.rotate(by: angleInRadians)
        context.translateBy(x: -0.5 * contextSize.width, y: -0.5 * contextSize.height)
        draw(at: .zero)
        
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}
