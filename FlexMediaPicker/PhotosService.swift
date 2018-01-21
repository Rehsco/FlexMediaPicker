//
//  PhotosService.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 06.11.2017.
/*
 * Copyright 2017-present Martin Jacob Rehder.
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
import Photos
import StyledOverlay

let photosService = PhotosService()

open class PhotosService: NSObject {

    func checkStatus(permissionGrantedHandler: @escaping (Bool)->Void) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            permissionGrantedHandler(true)
        case .denied, .notDetermined:
            PHPhotoLibrary.requestAuthorization { authorizationStatus -> Void in
                if authorizationStatus == .denied {
                    StyledMenuPopoverFactory.showSettingsRequest(title: FlexMediaPickerConfiguration.requestPermissionTitle, message: FlexMediaPickerConfiguration.requestPhotosPermissionMessage, configuration: FlexMediaPickerStyling.getPopoverViewAppearance())
                    permissionGrantedHandler(false)
                } else if authorizationStatus == .authorized {
                    permissionGrantedHandler(true)
                }
            }
        default:
            permissionGrantedHandler(false)
        }
    }
    
    // MARK: - Face detection
    
    func detectFaceRect(inImage image: UIImage) -> CGRect {
        let maxDim = max(image.size.width, image.size.height)
        // Default aspect ration - zero offset crop rect
        let cropRect = CGRect(x: 0, y: 0, width: image.size.height / maxDim, height: image.size.width / maxDim)
        
        if !FlexMediaPickerConfiguration.maskImageAutoCropToDetectedFace {
            return cropRect
        }
        
        let resImage: UIImage
        if image.size.width > image.size.height {
            // Face detection has issue with portrait images, so resize to square
            resImage = image.resized(newSize: CGSize(width: maxDim, height: maxDim))!
        }
        else {
            resImage = image
        }
        
        guard let personciImage = CIImage(image: resImage) else {
            return cropRect
        }
        
        let ciImageSize = personciImage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        
        let accuracy: [String : Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorImageOrientation: self.imageOrientationToCG(orientation: .up)]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        if let faces = faceDetector?.features(in: personciImage) {
            var largestRect: CGRect = .zero
            var largestArea: CGFloat = 0
            for face in faces as! [CIFaceFeature] {
                // Apply the transform to convert the coordinates
                let faceViewBounds = face.bounds.applying(transform)
                if faceViewBounds.width * faceViewBounds.height > largestArea {
                    largestArea = faceViewBounds.width * faceViewBounds.height
                    largestRect = faceViewBounds
                }
            }
            if largestArea > 0 {
                let cRect = CGRect(x: largestRect.minX / ciImageSize.width, y: largestRect.minY / ciImageSize.height, width: largestRect.width / ciImageSize.width, height: largestRect.height / ciImageSize.height)
                let scaledCropRect = cRect.insetBy(dx: (cRect.width - cRect.width * FlexMediaPickerConfiguration.faceDetectionCropScale) * 0.5, dy: (cRect.height - cRect.height * FlexMediaPickerConfiguration.faceDetectionCropScale) * 0.5)
                return scaledCropRect
            }
        }
        return cropRect
    }
    
    private func imageOrientationToCG(orientation:UIImageOrientation) -> CGImagePropertyOrientation {
        switch (orientation) {
        case .up:
            return CGImagePropertyOrientation.up
        case .upMirrored:
            return CGImagePropertyOrientation.upMirrored
        case .down:
            return CGImagePropertyOrientation.down
        case .downMirrored:
            return CGImagePropertyOrientation.downMirrored
        case .leftMirrored:
            return CGImagePropertyOrientation.leftMirrored
        case .right:
            return CGImagePropertyOrientation.right
        case .rightMirrored:
            return CGImagePropertyOrientation.rightMirrored
        case .left:
            return CGImagePropertyOrientation.left
        }
    }
}
