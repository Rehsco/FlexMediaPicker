// Adopted from RSKImageCropViewController.swift
// Original Copyright Notice

//
// RSKImageCropViewController.swift
//
// Copyright (c) 2014-present Ruslan Skorb, http://ruslanskorb.com/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import UIKit
import StyledLabel
import MJRFlexStyleComponents

// K is a constant such that the accumulated error of our floating-point computations is definitely bounded by K units in the last place.
#if arch(x86_64) || CPU_TYPE_ARM64
    let kK = CGFloat(9)
#else
    let kK = CGFloat(0)
#endif

/**
 The `RSKImageCropViewControllerDelegate` protocol defines messages sent to a image crop view controller delegate when crop image was canceled or the original image was cropped.
 */
public protocol RSKImageCropViewControllerDelegate: class {

    /**
     Tells the delegate that crop image has been canceled.
     */
    func didCancelCrop()

    /**
     Tells the delegate that the original image will be cropped.
     */
    func willCropImage(_ originalImage: UIImage)

    /**
     Tells the delegate that the original image has been cropped. Additionally provides a crop rect used to produce image.
     */
    func didCropImage(_ croppedImage: UIImage, usingCropRect cropRect: CGRect)

    /**
     Tells the delegate that the original image has been cropped. Additionally provides a crop rect and a rotation angle used to produce image.
     */
    func didCropImage(_ croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat)

}

/// TODO: create handlers instead of delegate

public class ImageCropView: CommonFlexView, UIGestureRecognizerDelegate {
    fileprivate let kResetAnimationDuration = CGFloat(0.4)
    fileprivate let kLayoutImageScrollViewAnimationDuration = CGFloat(0.25)
    private var undoMI: FlexMenuItem?

    fileprivate lazy var imageScrollView: RSKImageScrollView = {
        let view = RSKImageScrollView(frame: .zero)
        view.clipsToBounds = false
        view.isAspectFill = self.isAvoidEmptySpaceAroundImage
        return view
    }()

    fileprivate lazy var overlayView: RSKTouchView = {
        let view = RSKTouchView()
        view.receiver = self.imageScrollView
        view.layer.addSublayer(self.maskLayer)
        return view
    }()

    fileprivate lazy var maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillRule = kCAFillRuleEvenOdd
        layer.fillColor = FlexMediaPickerConfiguration.overlayMaskColor.cgColor
        return layer
    }()

    fileprivate lazy var doubleTapGestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        recognizer.delaysTouchesEnded = false
        recognizer.numberOfTapsRequired = 2
        recognizer.delegate = self
        return recognizer
    }()

    fileprivate lazy var rotationGestureRecognizer: UIRotationGestureRecognizer = {
        let recognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        recognizer.delaysTouchesEnded = false
        recognizer.delegate = self
        recognizer.isEnabled = self.isRotationEnabled
        return recognizer
    }()

    fileprivate var maskRect = CGRect.zero
    fileprivate var maskPath = UIBezierPath() {
        didSet {
            let clipPath = UIBezierPath(rect: rectForClipPath)
            clipPath.append(maskPath)
            clipPath.usesEvenOddFillRule = true
            
            let pathAnimation = CABasicAnimation(keyPath: "path")
            pathAnimation.duration = CATransaction.animationDuration()
            pathAnimation.timingFunction = CATransaction.animationTimingFunction()
            self.maskLayer.add(pathAnimation, forKey: "path")
            
            self.maskLayer.path = clipPath.cgPath
        }
    }

    public var isAvoidEmptySpaceAroundImage = true {
        didSet {
            imageScrollView.isAspectFill = isAvoidEmptySpaceAroundImage
        }
    }
    
    public var isApplyMaskToCroppedImage = false
    public var isRotationEnabled = false {
        didSet {
            rotationGestureRecognizer.isEnabled = isRotationEnabled
        }
    }
    
    fileprivate var originalImage: UIImage? {
        didSet {
            if self.window != nil {
                displayImage()
            }
        }
    }
    
    var imageCroppedHandler: ((CGRect)->Void)?
    fileprivate let initialCropRect: CGRect
    public weak var delegate: RSKImageCropViewControllerDelegate?

    public init(frame: CGRect, image: UIImage, cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) {
        self.initialCropRect = cropRect
        super.init(frame: frame)
        self.originalImage = image
        self.setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        self.initialCropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        super.init(coder: aDecoder)
        self.setupView()
    }

    private func setupView() {
        self.backgroundColor = FlexMediaPickerConfiguration.styleColor
        self.clipsToBounds = true
        
        self.headerText = "Crop Image"
        self.headerSize = FlexMediaPickerConfiguration.headerHeight
        self.header.styleColor = FlexMediaPickerConfiguration.headerColor

        self.addSubview(imageScrollView)
        self.addSubview(overlayView)
        
        self.addGestureRecognizer(doubleTapGestureRecognizer)
        self.addGestureRecognizer(rotationGestureRecognizer)
        
        self.rightViewMenu = CommonIconViewMenu(size: CGSize(width: 120, height: 36), hPos: .right, vPos: .header, menuIconSize: 24)
        self.undoMI = self.rightViewMenu?.createIconMenuItem(imageName: "undo", iconSize: 24, selectionHandler: {
            self.reset(animated: true)
        })
        self.rightViewMenu?.createIconMenuItem(imageName: "Accept", iconSize: 24, selectionHandler: {
            self.imageCroppedHandler?(self.relativeCropRect)
            self.closeView()
        })
        self.addMenu(self.rightViewMenu!)
        
        self.createBackOrCloseLeftMenu {
            self.closeView()
        }
    }

    private func closeView() {
        self.removeFromSuperview()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateMaskRect()
        layoutImageScrollView()
        layoutOverlayView()
        updateMaskPath()

        if imageScrollView.zoomView == nil {
            displayImage()
            self.setCropRectBasedOnRelativeRect(self.initialCropRect)
        }
    }

    // MARK: - Custom Accessors

    fileprivate var relativeCropRect: CGRect {
        guard let originalImage = originalImage else { return CGRect(x: 0, y: 0, width: 0, height: 0) }
        let absRect = self.cropRect
        return CGRect(x: self.imageScrollView.contentOffset.x / originalImage.size.width,
                      y: self.imageScrollView.contentOffset.y / originalImage.size.height,
                      width: self.imageScrollView.bounds.width / absRect.width,
                      height: self.imageScrollView.bounds.height / absRect.height)
    }
    
    fileprivate func setCropRectBasedOnRelativeRect(_ rect: CGRect) {
        guard let originalImage = originalImage else { return }
        
        self.imageScrollView.zoomScale = min(rect.width, rect.height)
        
        let contentOffset = CGPoint(x: rect.origin.x * originalImage.size.width, y: rect.origin.y * originalImage.size.height)
        self.imageScrollView.contentOffset = contentOffset
    }
    
    fileprivate var cropRect: CGRect {
        var rect = CGRect.zero
        let zoomScale = 1.0 / imageScrollView.zoomScale
        
        rect.origin.x = round(imageScrollView.contentOffset.x * zoomScale)
        rect.origin.y = round(imageScrollView.contentOffset.y * zoomScale)
        rect.size.width = imageScrollView.bounds.width * zoomScale
        rect.size.height = imageScrollView.bounds.height * zoomScale
        
        let width = rect.width
        let height = rect.height
        let ceilWidth = ceil(width)
        let ceilHeight = ceil(height)
        
        if fabs(ceilWidth - width) < pow(10, kK) * RSK_EPSILON * fabs(ceilWidth + width) || fabs(ceilWidth - width) < RSK_MIN ||
            fabs(ceilHeight - height) < pow(10, kK) * RSK_EPSILON * fabs(ceilHeight + height) || fabs(ceilHeight - height) < RSK_MIN
        {
            rect.size.width = ceilWidth
            rect.size.height = ceilHeight
        } else {
            rect.size.width = floor(width)
            rect.size.height = floor(height)
        }
        
        return rect
    }

    fileprivate var rectForClipPath: CGRect {
        return overlayView.frame
    }

    fileprivate var rectForMaskPath: CGRect {
        return maskRect
    }

    internal var rotationAngle: CGFloat {
        get {
            let transform = imageScrollView.transform
            return atan2(transform.b, transform.a)
        }
        
        set(rotationAngle) {
            if self.rotationAngle != rotationAngle {
                let rotation = (rotationAngle - self.rotationAngle)
                let transform = imageScrollView.transform.rotated(by: rotation)
                imageScrollView.transform = transform
            }
        }
    }

    fileprivate var zoomScale: CGFloat {
        return imageScrollView.zoomScale
    }

    fileprivate func setZoomScale(_ zoomScale: CGFloat) {
        self.imageScrollView.zoomScale = zoomScale
    }

    // MARK: - Action handling

    @objc fileprivate func handleDoubleTap(gestureRecognizer: UITapGestureRecognizer) {
        reset(animated: true)
    }

    @objc fileprivate func handleRotation(gestureRecognizer: UIRotationGestureRecognizer) {
        rotationAngle += gestureRecognizer.rotation
        gestureRecognizer.rotation = 0
        
        if gestureRecognizer.state == .ended {
            UIView.animate(
                withDuration: TimeInterval(kLayoutImageScrollViewAnimationDuration),
                delay: 0.0,
                options: .beginFromCurrentState,
                animations: {
                    self.layoutImageScrollView()
                },
                completion:nil)
        }
    }

    // MARK: - Private
    
    fileprivate func reset(animated: Bool) {
        if animated {
            UIView.beginAnimations("rsk_reset", context: nil)
            UIView.setAnimationCurve(.easeInOut)
            UIView.setAnimationDuration(TimeInterval(kResetAnimationDuration))
            UIView.setAnimationBeginsFromCurrentState(true)
        }
        
        resetRotation()
        resetFrame()
        resetZoomScale()
        resetContentOffset()
        
        if animated {
            UIView.commitAnimations()
        }
    }

    fileprivate func resetContentOffset() {
        guard let zoomView = imageScrollView.zoomView else { return }
        
        let boundsSize = imageScrollView.bounds.size
        let frameToCenter = zoomView.frame
        
        var contentOffset = CGPoint(x: 0.0, y: 0.0)
        if frameToCenter.width > boundsSize.width {
            contentOffset.x = (frameToCenter.width - boundsSize.width) * 0.5
        } else {
            contentOffset.x = 0
        }
        if (frameToCenter.height > boundsSize.height) {
            contentOffset.y = (frameToCenter.height - boundsSize.height) * 0.5
        } else {
            contentOffset.y = 0
        }
        
        self.imageScrollView.contentOffset = contentOffset
    }

    fileprivate func resetFrame() {
        layoutImageScrollView()
    }

    fileprivate func resetRotation() {
        rotationAngle = 0.0
    }

    fileprivate func resetZoomScale() {
        guard let originalImage = originalImage else { return }
    
        let vr = self.getViewRect()
        var zoomScale = CGFloat(0.0)
        if vr.width > vr.height {
            zoomScale = vr.height / originalImage.size.height
        } else {
            zoomScale = vr.width / originalImage.size.width
        }
        self.imageScrollView.zoomScale = zoomScale
    }

    fileprivate func intersectionPointsOfLineSegment(lineSegment: RSKLineSegment, withRect rect: CGRect) -> [CGPoint] {
        let top = RSKLineSegmentMake(
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.minY))
        
        let right = RSKLineSegmentMake(
            start: CGPoint(x: rect.maxX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.maxY))
        
        let bottom = RSKLineSegmentMake(
            start: CGPoint(x: rect.minX, y: rect.maxY),
            end: CGPoint(x: rect.maxX, y: rect.maxY))
        
        let left = RSKLineSegmentMake(
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.minX, y: rect.maxY))
        
        let p0 = RSKLineSegmentIntersection(ls1: top, ls2: lineSegment)
        let p1 = RSKLineSegmentIntersection(ls1: right, ls2: lineSegment)
        let p2 = RSKLineSegmentIntersection(ls1: bottom, ls2: lineSegment)
        let p3 = RSKLineSegmentIntersection(ls1: left, ls2: lineSegment)
        
        var intersectionPoints = [CGPoint]()
        if !RSKPointIsNull(p0) {
            intersectionPoints.append(p0)
        }
        if !RSKPointIsNull(p1) {
            intersectionPoints.append(p1)
        }
        if !RSKPointIsNull(p2) {
            intersectionPoints.append(p2)
        }
        if !RSKPointIsNull(p3) {
            intersectionPoints.append(p3)
        }
        
        return intersectionPoints
    }

    fileprivate func displayImage() {
        guard let originalImage = originalImage else { return }
        
        imageScrollView.displayImage(originalImage)
        reset(animated: false)
    }

    fileprivate func layoutImageScrollView() {
        let transform = imageScrollView.transform
        imageScrollView.transform = .identity
        imageScrollView.frame = maskRect
        imageScrollView.transform = transform
    }

    fileprivate func layoutOverlayView() {
        let vr = self.getViewRect()
        let frame = CGRect(x: 0, y: 0, width: vr.width * 2, height: vr.height * 2)
        overlayView.frame = frame
    }

    fileprivate func updateMaskRect() {
        // TODO: must adhere to fitting settings
        self.maskRect = CGRectHelper.AspectFitRectInRect(CGRect(x: 0, y: 0, width: 1, height: 1), rtarget: self.getViewRect())
    }

    fileprivate func updateMaskPath() {
        self.maskPath = StyledShapeLayer.shapePathForStyle(FlexMediaPickerConfiguration.imageMaskStyle.style, bounds: rectForMaskPath)
    }

    fileprivate func croppedImage(image: UIImage, cropRect: CGRect, scale imageScale: CGFloat, orientation imageOrientation: UIImageOrientation) -> UIImage {
        if let images = image.images {
            var croppedImages = [UIImage]()
            
            images.forEach {
                croppedImages.append(croppedImage(image: $0, cropRect: cropRect, scale: imageScale, orientation: imageOrientation))
            }
            
            return UIImage.animatedImage(with: croppedImages, duration: image.duration)!
        } else {
            if let croppedCGImage = image.cgImage!.cropping(to: cropRect) {
                return UIImage(cgImage: croppedCGImage, scale: imageScale, orientation: imageOrientation)
            }
            
            return image
        }
    }

    fileprivate func croppedImage(image: UIImage, cropRect cropRect0: CGRect, rotationAngle: CGFloat, zoomScale: CGFloat, maskPath: UIBezierPath, applyMaskToCroppedImage: Bool) -> UIImage {
        var cropRect = cropRect0
        
        // Step 1: check and correct the crop rect.
        let imageSize = image.size
        let x = cropRect.minX
        let y = cropRect.minY
        let width = cropRect.width
        let height = cropRect.height
        
        var imageOrientation = image.imageOrientation
        if imageOrientation == .right || imageOrientation == .rightMirrored {
            cropRect.origin.x = y
            cropRect.origin.y = round(imageSize.width - cropRect.width - x)
            cropRect.size.width = height
            cropRect.size.height = width
        } else if imageOrientation == .left || imageOrientation == .leftMirrored {
            cropRect.origin.x = round(imageSize.height - cropRect.height - y)
            cropRect.origin.y = x
            cropRect.size.width = height
            cropRect.size.height = width
        } else if imageOrientation == .down || imageOrientation == .downMirrored {
            cropRect.origin.x = round(imageSize.width - cropRect.width - x)
            cropRect.origin.y = round(imageSize.height - cropRect.height - y)
        }
        
        let imageScale = image.scale
        cropRect = cropRect.applying(CGAffineTransform(scaleX: imageScale, y: imageScale))
        
        // Step 2: create an image using the data contained within the specified rect.
        var croppedImage = self.croppedImage(image: image, cropRect: cropRect, scale: imageScale, orientation: imageOrientation)
        
        // Step 3: fix orientation of the cropped image.
        croppedImage = croppedImage.fixOrientation()
        imageOrientation = croppedImage.imageOrientation
        
        // Step 5: create a new context.
        let maskSize = maskPath.bounds.integral.size
        let contextSize = CGSize(
            width: ceil(maskSize.width / zoomScale),
            height: ceil(maskSize.height / zoomScale))
        
        UIGraphicsBeginImageContextWithOptions(contextSize, false, imageScale)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return croppedImage
        }
        
        defer {
            UIGraphicsEndImageContext()
        }
        
        // Step 6: apply the mask if needed.
        if applyMaskToCroppedImage {
            // 6a: scale the mask to the size of the crop rect.
            let maskPathCopy = maskPath.copy() as! UIBezierPath
            let scale = 1 / zoomScale
            maskPathCopy.apply(CGAffineTransform(scaleX: scale, y: scale))
            
            // 6b: move the mask to the top-left.
            let translation = CGPoint(x: -maskPathCopy.bounds.minX, y: -maskPathCopy.bounds.minY)
            maskPathCopy.apply(CGAffineTransform(translationX: translation.x, y: translation.y))
            
            // 6c: apply the mask.
            maskPathCopy.addClip()
        }
        
        // Step 7: rotate the cropped image if needed.
        if rotationAngle != 0 {
            croppedImage = croppedImage.rotateByAngle(angleInRadians: rotationAngle)
        }
        
        // Step 8: draw the cropped image.
        let point = CGPoint(
            x: round((contextSize.width - croppedImage.size.width) * 0.5),
            y: round((contextSize.height - croppedImage.size.height) * 0.5))
        croppedImage.draw(at: point)
        
        // Step 9: get the cropped image affter processing from the context.
        croppedImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        // Step 10: return the cropped image affter processing.
        
        return UIImage(cgImage: croppedImage.cgImage!, scale: imageScale, orientation: imageOrientation)
    }

    internal func cropImage() {
        guard let originalImage = originalImage else { return }
        
        delegate?.willCropImage(originalImage)
        
        DispatchQueue.global(qos: .default).async {
            let croppedImage = self.croppedImage(
                image: originalImage,
                cropRect: self.cropRect,
                rotationAngle: self.rotationAngle,
                zoomScale: self.imageScrollView.zoomScale,
                maskPath: self.maskPath,
                applyMaskToCroppedImage: self.isApplyMaskToCroppedImage)
            
            DispatchQueue.main.async {
                self.delegate?.didCropImage(croppedImage, usingCropRect: self.cropRect, rotationAngle: self.rotationAngle)
            }
        }
    }

    fileprivate func cancelCrop() {
        delegate?.didCancelCrop()
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
