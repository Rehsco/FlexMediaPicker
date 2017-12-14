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
    var secRef: String?
    var allPopulatedItems: [ImagesCollectionItem] = []
    
    open var deleteOrRemoveItemHandler: ((String)->Void)?
    
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
    
    open func focusOnItem(withReference reference: String) {
        DispatchQueue.main.async {
            if let ip = self.getIndexPathForItem(reference) {
                if self.bounds.size.width > self.bounds.size.height {
                    self.itemCollectionView.scrollToItem(at: ip, at: .centeredHorizontally, animated: true)
                }
                else {
                    self.itemCollectionView.scrollToItem(at: ip, at: .centeredVertically, animated: true)
                }
                self.allPopulatedItems.forEach({ item in
                    item.isFocused = false
                    self.updateCellForItem(item.reference)
                })
                if let item = self.getItemForReference(reference) as? ImagesCollectionItem {
                    item.isFocused = true
                    self.updateCellForItem(reference)
                }
            }
        }
    }
    
    open func refreshItem(withReference reference: String) {
        DispatchQueue.main.async {
            if let item = self.getItemForReference(reference) as? ImagesCollectionItem, let asset = AssetManager.persistence.getAsset(forID: item.reference) {
                self.populateItemInfo(forAsset: asset, item: item)
                self.updateCellForItem(reference)
            }
        }
    }
    
    open func getFocusedMediaAsset() -> FlexMediaPickerAsset? {
        for item in self.allPopulatedItems {
            if item.isFocused {
                let asset = AssetManager.persistence.getAsset(forID: item.reference)
                return asset
            }
        }
        return nil
    }
    
    open func populate(focusOnLastItem: Bool = false, showImageHandler: @escaping ((Int)->Void)) {
        DispatchQueue.main.async {
            self.removeAllSections()
            self.allPopulatedItems = []
            self.secRef = self.addSection()
            let allSelectedAssets = AssetManager.persistence.getAllAssets()
            var idx = 0
            var lastItem: ImagesCollectionItem? = nil
            for selAsset in allSelectedAssets {
                let ref = selAsset.uuid // selAsset.asset?.localIdentifier ?? UUID().uuidString
                let thumbnail: UIImage?
                if selAsset.isVideo() || selAsset.isAudio() {
                    thumbnail = selAsset.thumbnail
                }
                else {
                    thumbnail = self.maskImage(selAsset.thumbnail, cropRect: selAsset.cropRect)
                }
                let fitem = ImagesCollectionItem(reference: ref, icon: thumbnail)
                
                self.populateItemInfo(forAsset: selAsset, item: fitem)
                
                fitem.canMoveItem = false
                fitem.imageViewFitting = .scaleToFit
                fitem.contentInteractionWillSelectItem = true
                fitem.autoDeselectCellAfter = .milliseconds(300)
                fitem.imageIndex = idx
                fitem.itemSelectionActionHandler = {
                    showImageHandler(fitem.imageIndex)
                    self.focusOnItem(withReference: ref)
                }
                let selectionItemMenu = CommonIconViewMenu(size: CGSize(width: 24, height: 24), hPos: .left, vPos: .header, menuIconSize: 24)
                let imageName = selAsset.isAssetBased() ? "RemoveItem" : "DeleteIcon"
                _ = selectionItemMenu.createIconMenuItem(imageName: imageName, iconSize: 24, selectionHandler: {
                    if !selAsset.isAssetBased() {
                        AlertViewFactory.confirmation(title: FlexMediaPickerConfiguration.deleteItemTitle, subTitle: FlexMediaPickerConfiguration.deleteItemMessage, buttonText: FlexMediaPickerConfiguration.deleteItemButtonText, iconName: FlexMediaPickerConfiguration.queryIconName, confirmationResult: { proceed in
                            if proceed {
                                self.deleteOrRemoveItemHandler?(fitem.reference)
                            }
                        })
                    }
                    else {
                        self.deleteOrRemoveItemHandler?(fitem.reference)
                    }
                })
                fitem.itemMenu = selectionItemMenu
                self.addItem(self.secRef!, item: fitem)

                idx += 1
                lastItem = fitem
                self.allPopulatedItems.append(fitem)
            }
            self.itemCollectionView.reloadData()
            if focusOnLastItem, let li = lastItem {
                self.focusOnItem(withReference: li.reference)
            }
        }
    }
    
    private func populateItemInfo(forAsset asset: FlexMediaPickerAsset, item: ImagesCollectionItem) {
        if asset.isVideo() || asset.isAudio() {
            AssetManager.croppedDuration(forMediaAsset: asset, durationHandler: { duration in
                let timeStr = Helper.stringFromTimeInterval(interval: duration)
                let maxAllowedDuration = asset.isVideo() ? FlexMediaPickerConfiguration.maxVideoRecordingTime : FlexMediaPickerConfiguration.maxAudioRecordingTime
                if maxAllowedDuration > 0 && round(duration) > maxAllowedDuration {
                    item.secondarySubTitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.selectedMediaCaptionFont, color: FlexMediaPickerConfiguration.secondWarningOfRecordingTimeColor, text: timeStr)
                    if let warnIcon = Helper.getWarningIcon() {
                        item.subTitle = Helper.imageToAttachmentImage(warnIcon, fontSize: FlexMediaPickerConfiguration.selectedMediaCaptionFont.pointSize)
                    }
                }
                else {
                    item.secondarySubTitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.selectedMediaCaptionFont, color: FlexMediaPickerConfiguration.selectedMediaCaptionColor, text: timeStr)
                    item.subTitle = NSAttributedString(string: "")
                }
                DispatchQueue.main.async {
                    self.updateCellForItem(item.reference)
                }
            })
            
            if asset.isVideo(), !FlexMediaPickerConfiguration.allowVideoSelection, let warnIcon = Helper.getWarningIcon() {
                item.subTitle = Helper.imageToAttachmentImage(warnIcon, fontSize: FlexMediaPickerConfiguration.selectedMediaCaptionFont.pointSize)
            }
        }
    }
    
    private func maskImage(_ image: UIImage, cropRect: CGRect) -> UIImage {
        if FlexMediaPickerConfiguration.maskImage {
            let imgRect = CGRect(origin: .zero, size: image.size)
            let imgCropRect = CGRect(x: cropRect.origin.x * imgRect.width, y: cropRect.origin.y * imgRect.height, width: cropRect.width * imgRect.width, height: cropRect.height * imgRect.height)
//            NSLog("imgCropRect: \(imgCropRect)")
            let croppedImage = image.crop(toRect: imgCropRect)
            let cimgRect = CGRect(origin: .zero, size: croppedImage.size)
//            NSLog("cimgRect: \(cimgRect)")
            let maskRect = Helper.getMaskRect(inRect: cimgRect)
            let maskShape = StyledShapeLayer.createShape(FlexMediaPickerConfiguration.imageMaskStyle.style, bounds: maskRect, color: .black)
            let maskPath = UIBezierPath(cgPath: maskShape.path!)
            return croppedImage.maskImageWithPath(maskPath)
        }
        return image
    }

}
