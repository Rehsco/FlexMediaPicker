//
//  SelectedAssetsCollectionView.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 07.11.2017.
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
import MJRFlexStyleComponents
import StyledLabel

open class SelectedAssetsCollectionView: ImagesCollectionView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupAssetsView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func setupAssetsView() {
        self.registerCell(ImagesCollectionItem.self, cellClass: ImagesCollectionCell.self)
    }
    
    open func populate(_ showImageHandler: @escaping ((Int)->Void)) {
        DispatchQueue.main.async {
            self.removeAllSections()
            let savSecRef = self.addSection()
            let allSelectedAssets = AssetManager.persistence.getAllAssets()
            var idx = 0
            for selAsset in allSelectedAssets {
                let ref = selAsset.asset?.localIdentifier ?? UUID().uuidString
                let thumbnail: UIImage?
                if selAsset.isVideo() || selAsset.isAudio() {
                    thumbnail = selAsset.thumbnail
                }
                else {
                    thumbnail = self.maskImage(selAsset.thumbnail, cropRect: selAsset.cropRect)
                }
                let fitem = ImagesCollectionItem(reference: ref, icon: thumbnail)
                
                if selAsset.isVideo() || selAsset.isAudio() {
                    // TODO: use cached and / or cropped duration
                    AssetManager.duration(forMediaAsset: selAsset, durationHandler: { duration in
                        let timeStr = Helper.stringFromTimeInterval(interval: TimeInterval(duration))
                        fitem.secondarySubTitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.selectedMediaCaptionFont, color: FlexMediaPickerConfiguration.selectedMediaCaptionColor, text: timeStr)
                        DispatchQueue.main.async {
                            self.updateCellForItem(fitem.reference)
                        }
                    })
                    
                    if selAsset.isVideo(), !FlexMediaPickerConfiguration.allowVideoSelection, let warnIcon = Helper.getWarningIcon() {
                        fitem.subTitle = Helper.imageToAttachmentImage(warnIcon, fontSize: FlexMediaPickerConfiguration.selectedMediaCaptionFont.pointSize)
                    }
                }
                
                fitem.canMoveItem = false
                fitem.imageViewFitting = .scaleToFit
                fitem.contentInteractionWillSelectItem = true
                fitem.autoDeselectCellAfter = .milliseconds(300)
                fitem.imageIndex = idx
                fitem.itemSelectionActionHandler = {
                    showImageHandler(fitem.imageIndex)
                }
                self.addItem(savSecRef, item: fitem)
                idx += 1
            }
            self.itemCollectionView.reloadData()
        }
    }
    
    private func maskImage(_ image: UIImage, cropRect: CGRect) -> UIImage {
        NSLog("Mask photo to cropRect \(cropRect) of image with size: \(image.size)")
        if FlexMediaPickerConfiguration.maskImage {
            let imgRect = CGRect(origin: .zero, size: image.size)
            let imgCropRect = CGRect(x: cropRect.origin.x * imgRect.width, y: cropRect.origin.y * imgRect.height, width: cropRect.width * imgRect.width, height: cropRect.height * imgRect.height)
            NSLog("imgCropRect: \(imgCropRect)")
            let croppedImage = image.crop(toRect: imgCropRect)
            let cimgRect = CGRect(origin: .zero, size: croppedImage.size)
            NSLog("cimgRect: \(cimgRect)")
            let maskRect = Helper.getMaskRect(inRect: cimgRect)
            let maskShape = StyledShapeLayer.createShape(FlexMediaPickerConfiguration.imageMaskStyle.style, bounds: maskRect, color: .black)
            let maskPath = UIBezierPath(cgPath: maskShape.path!)
            return croppedImage.maskImageWithPath(maskPath)
        }
        return image
    }

}
