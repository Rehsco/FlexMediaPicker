//
//  FlexMediaPickerViewController.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 25.08.17.
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
import DateToolsSwift
import Photos
import ImageSlideshow
import CoreLocation
import ImagePersistence
import TaskQueue
import StyledLabel
import MapKit

class ImageMediaCollectionView: ImagesCollectionView {
    private var mediaControlPanel = MainMediaControlPanel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    override var footer: FlexFooterView {
        return self.mediaControlPanel
    }
}

open class FlexMediaPickerViewController: CommonFlexCollectionViewController {
    private var viewInitiating = true
    
    private var closeViewMenu: CommonIconViewMenu?
    private var backViewMenu: CommonIconViewMenu?
    private var acceptMI: FlexMenuItem?
    
    private var assetThumbnailCache = ImageCache()
    private var assetCollections: [PHAssetCollection] = []
    private var smartAssetCollections: [PHAssetCollection] = []
    private var assetCache: [PHAsset] = []
    private var currentAssetCollection: PHAssetCollection?

    private var imageSlideshowView: ImageSlideShowView?

    private var cameraView: CameraView?
    private var voiceRecorderView: VoiceRecorderView?

    private var imageSources: [ImageAssetImageSource] = []
    private var selectedAssetsView: SelectedAssetsCollectionView?
    
    // MARK: - Public accessors
    
    public var mediaAcceptedHandler: (([FlexMediaPickerAsset])->Void)?
    
    // MARK: - View Init
    
    open override var prefersStatusBarHidden: Bool {
        return FlexMediaPickerConfiguration.statusBarHidden
    }
    
    override open func setupView() {
        self.headerText = FlexMediaPickerConfiguration.mediaTitle

        super.setupView()

        FlexMediaPickerStyling.applyStyling()
        
        self.contentView = ImageMediaCollectionView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.contentView?.headerFooterAdaptToMenu = false
        self.contentView?.registerCell(ImagesCollectionItem.self, cellClass: ImagesCollectionCell.self)
        self.view.addSubview(self.contentView!)
        self.applyCollectionViewDefaultStyling(collectionView: self.contentView!)
        self.contentView?.header.caption.labelFont = FlexMediaPickerConfiguration.headerFont

        self.contentView?.header.subCaption.labelTextAlignment = .center
        self.contentView?.header.subCaption.labelFont = FlexMediaPickerConfiguration.headerSubCaptionFont
        self.contentView?.header.subCaption.labelTextColor = FlexMediaPickerConfiguration.headerTextColor

        self.createIconMenu(width: 120, menuIconSize: 24)
        self.acceptMI = self.rightViewMenu?.createIconMenuItem(imageName: "Accept", selectionHandler: {
            self.convertSelectedVideoAssets {
                let aa = self.getAcceptedAssets()
                self.mediaAcceptedHandler?(aa)
            }
        })
        self.contentView?.addMenu(self.rightViewMenu!)
        self.rightViewMenu?.viewMenuItems[0].enabled = false
 
        self.createBackOrCloseLeftMenu(menuIconSize: 24)
        
        self.backViewMenu = CommonIconViewMenu(size: CGSize(width: 50, height: 36), hPos: .left, vPos: .header, menuIconSize: 24)
        self.backViewMenu?.createBackIconMenuItem()
        self.backViewMenu?.menuSelectionHandler = {
            type in
            if type == .back {
                self.currentAssetCollection = nil
                self.contentView?.removeMenu(self.backViewMenu!)
                self.contentView?.addMenu(self.leftViewMenu!)
                self.contentView?.setNeedsLayout()
                self.populateContent()
            }
        }
        
        // The selected assets will be shown in a sub view
        self.selectedAssetsView = SelectedAssetsCollectionView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if let sav = self.selectedAssetsView {
            self.applyCollectionViewDefaultStyling(collectionView: sav)
            sav.styleColor = FlexMediaPickerConfiguration.selectedMediaStyleColor
            (sav.itemCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
            sav.centerCellsHorizontally = true
            sav.isHidden = true
            self.view.addSubview(sav)
        }
        
        // Media Control panel at the bottom of the view
        self.contentView?.footerSize = FlexMediaPickerConfiguration.footerHeight
        self.contentView?.footerText = " "
        if let mcp = self.contentView?.footer as? MediaControlPanel {
            if let cv = self.contentView {
                mcp.setupMenu(in: cv)
            }
            mcp.actionActivationHandler = {
                action in
                switch action {
                case .camera:
                    cameraService.checkPermission(permissionGrantedHandler: { accessGranted in
                        if accessGranted {
                            self.showCameraView()
                        }
                    })
                case .location:
                    if LocationService.isCurrentlyAuthorized() {
                        self.addCurrentLocationAsImage()
                    }
                    else {
                        locationService.checkAuthorization(true)
                    }
                case .microphone:
                    if audioService.isAudioRecordingGranted {
                        self.showVoiceRecorderView()
                    }
                    else {
                        audioService.requestPermission()
                    }
                default:
                    break
                }
            }
        }
    }

    // MARK: - View Logic
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.isNavigationBarHidden = true
        
        // Only do this if the view has just initiated
        if self.viewInitiating {
            self.viewInitiating = false
            self.applyThumbnailSize()
        }
        
        self.contentView?.itemCollectionView.allowsMultipleSelection = FlexMediaPickerConfiguration.allowMultipleSelection
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if FlexMediaPickerConfiguration.allowLocationSelection || FlexMediaPickerConfiguration.recordLocationOnPhoto {
            locationService.checkAuthorization(true)
        }
        if FlexMediaPickerConfiguration.allowVoiceRecording {
            audioService.checkPermission()
        }
        self.checkStatus()
        self.layoutSupplementaryViews(to: self.view.bounds.size)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cameraView?.closeView()
    }
    
    override open func whenTransition(to size: CGSize) {
        super.whenTransition(to: size)
        self.contentView?.setNeedsDisplay()
        self.layoutSupplementaryViews(to: size)
    }
    
    func layoutSupplementaryViews(to size: CGSize) {
        if size.width > size.height {
            self.cameraView?.headerPosition = .left
            if self.cameraView != nil {
                (self.selectedAssetsView?.itemCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .vertical
            }
            else {
                (self.selectedAssetsView?.itemCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
            }
        }
        else {
            self.cameraView?.headerPosition = .top
            (self.selectedAssetsView?.itemCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
        }
        self.selectedAssetsView?.setNeedsLayout()
        self.selectedAssetsView?.itemCollectionView.reloadData()
    }
    
    override open func refreshView() {
        self.contentView?.headerText = self.headerText
        self.contentView?.subHeaderText = self.getItemsCountStr()

        var tabbarSize: CGFloat = 0
        if let tbc = self.tabBarController {
            tabbarSize = tbc.tabBar.isHidden ? 0 : tbc.tabBar.bounds.size.height - 3
        }

        /// TODO: This must change for SafeAreaInsets and iPhone X
        if let sav = self.selectedAssetsView, !sav.isHidden {
            self.contentView?.viewMargins = UIEdgeInsetsMake(0, 0, 120, 0)
        }
        else {
            self.contentView?.viewMargins = UIEdgeInsetsMake(0, 0, 0, 0)
        }
        self.selectedAssetsView?.frame = self.selectedAssetsViewRect()

        var resBounds = self.view.bounds.offsetBy(dx: 0, dy: UIApplication.shared.statusBarFrame.height * 0.5).insetBy(dx: 0, dy: UIApplication.shared.statusBarFrame.height * 0.5)
        resBounds = CGRect(origin: resBounds.origin, size: CGSize(width: resBounds.size.width, height: resBounds.size.height-tabbarSize))
        self.contentView?.frame = resBounds
        
        let camRect = self.view.bounds
        self.cameraView?.frame = camRect
        self.cameraView?.setNeedsLayout()
        
        self.imageSlideshowView?.frame = self.view.bounds
        self.voiceRecorderView?.frame = self.view.bounds

        super.refreshView()
    }
    
    private func selectedAssetsViewRect() -> CGRect {
        if self.cameraView != nil && (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight) {
            return CGRect(x: self.view.bounds.size.width - (120 + 64), y: 0, width: 120, height: self.view.bounds.size.height)
        }
        return CGRect(x: 0, y: self.view.bounds.size.height - (120 + 64), width: self.view.bounds.size.width, height: 120)
    }
    
    // MARK: - Camera View
    
    private func showCameraView() {
        if self.cameraView == nil {
            self.cameraView = CameraView(frame: self.view.bounds)
            self.view.insertSubview(self.cameraView!, at: 1)
            self.cameraView?.headerFooterAdaptToMenu = false
            self.cameraView?.displayView()
            self.cameraView?.didGetPhoto = {
                image, location in
                self.addNewImage(image, location: location)
            }
            self.cameraView?.cancelCameraViewHandler = {
                self.cameraView?.removeFromSuperview()
                self.cameraView = nil
            }
            self.cameraView?.didRecordVideo = {
                mpa in
                self.addSelectedAsset(mpa)
            }
            self.layoutSupplementaryViews(to: self.view.bounds.size)
        }
    }
    
    // MARK: - Voice Recording
    
    private func showVoiceRecorderView() {
        if self.voiceRecorderView == nil {
            self.voiceRecorderView = VoiceRecorderView(frame: self.view.bounds)
            self.view.insertSubview(self.voiceRecorderView!, at: 1)
            self.voiceRecorderView?.headerFooterAdaptToMenu = false
            self.voiceRecorderView?.cancelVoiceRecorderViewHandler = {
                self.voiceRecorderView?.removeFromSuperview()
                self.voiceRecorderView = nil
            }
            self.voiceRecorderView?.didRecordAudio = {
                mpa in
                self.addSelectedAsset(mpa)
            }
            self.voiceRecorderView?.voiceRecordingFailedHandler = {
                // TODO: Notify
            }
            self.layoutSupplementaryViews(to: self.view.bounds.size)
        }
    }
    
    // MARK: - Item Access
    
    func checkStatus() {
        photosService.checkStatus { accessGranted in
            if accessGranted {
                self.permissionGranted()
            }
            else {
                self.closeView()
            }
        }
    }
    
    func permissionGranted() {
        AssetManager.fetchAssetCollections { collections in
            self.assetCollections = collections
            self.populateContent()
        }
        AssetManager.fetchSmartAssetCollections { collections in
            self.smartAssetCollections = collections
            self.populateContent()
        }
    }
    
    // MARK: - Item handling

    private func convertSelectedVideoAssets(completedHandler: @escaping (()->Void)) {
        let aAssets = self.getAcceptedAssets()
        var assetsToConvert: [FlexMediaPickerAsset] = []
        for aa in aAssets {
            // TODO: Only convert (audio / video) when required
            if FlexMediaPickerConfiguration.allowVideoSelection && aa.isVideo() {
                assetsToConvert.append(aa)
            }
            if FlexMediaPickerConfiguration.allowVoiceRecording && aa.isAudio() {
                assetsToConvert.append(aa)
            }
        }
        
        BusyViewFactory.showProgressOverlay(onView: nil, completionHandler: {
            var idx = 1
            let assetsConvertCount = assetsToConvert.count
            let queue = TaskQueue()
            
            for _ in 0..<assetsConvertCount {
                queue.tasks +=~ { result, next in
                    BusyViewFactory.updateProgress(progress: 0, upperLabel: "Converting Media", lowerLabel: "\(idx) of \(assetsConvertCount)")
                    
                    if let assetToConvert = assetsToConvert.first != nil ? assetsToConvert.removeFirst() : nil {
                        if assetToConvert.isVideo() {
                            AssetManager.reencodeVideo(forMediaAsset: assetToConvert, progressHandler: { progress in
                                BusyViewFactory.updateProgress(progress: progress, upperLabel: "Converting Video", lowerLabel: "\(idx) of \(assetsConvertCount)")
                            }, completedURLHandler: { url in
                                AssetManager.storeVideo(forURL: url, completion: { _ in
                                    NSLog("re-encoded video stored to Photos (as test)")
                                    next(nil)
                                })
                            })
                        }
                        else if assetToConvert.isAudio() {
                            AssetManager.cropAudio(forMediaAsset: assetToConvert, progressHandler: { progress in
                                BusyViewFactory.updateProgress(progress: progress, upperLabel: "Converting Audio", lowerLabel: "\(idx) of \(assetsConvertCount)")
                            }, completedURLHandler: { url in
                                AssetManager.storeVideo(forURL: url, completion: { _ in
                                    NSLog("re-encoded audio stored to Photos (as test)")
                                    next(nil)
                                })
                            })
                        }
                    }
                }
                
                queue.tasks +=! {
                    idx += 1
                }
            }
            
            queue.run {
                BusyViewFactory.hideProgressOverlay() {
                    completedHandler()
                }
            }
        })
    }
    
    func fetchAssets(in collection: PHAssetCollection) {
        self.currentAssetCollection = collection
        self.contentView?.removeMenu(self.leftViewMenu!)
        self.contentView?.addMenu(self.backViewMenu!)
        self.contentView?.setNeedsLayout()
        AssetManager.fetch(in: collection) { fetchedAssets in
            self.assetCache = fetchedAssets
            self.populateContent()
        }
    }
    
    private func addNewImage(_ image: UIImage, location: CLLocation?) {
        let thImageSize = CGSize(width: FlexMediaPickerConfiguration.thumbnailSize.width * 2, height: FlexMediaPickerConfiguration.thumbnailSize.height * 2)
        if FlexMediaPickerConfiguration.storeTakenImagesToPhotos {
            let img = image.fixOrientation()
            
            NSLog("Saving photo")
            AssetManager.savePhoto(img, location: location) {
                newAsset in
                if let imageAsset = newAsset {
                    NSLog("Saved photo has local ID \(imageAsset.localIdentifier)")
                    self.addSelectedAsset(imageAsset, thumbnail: img.scaleToSizeKeepAspect(size: thImageSize))
                }
            }
        }
        else {
            let imageAsset = AssetManager.persistence.createImageAsset(thumbnail: image.scaleToSizeKeepAspect(size: thImageSize), image: image)
            self.addSelectedAsset(imageAsset)
        }
    }

    private func addSelectedAsset(_ asset: FlexMediaPickerAsset) {
        let ias = ImageAssetImageSource(asset: asset)
        self.imageSources.append(ias)
        if let issv = self.imageSlideshowView {
            issv.imageSlideshow?.setImageInputs(self.imageSources)
        }
        self.populateSelectedAssetView()
    }

    private func applyThumbnailSize() {
        if let icv = self.contentView as? ImagesCollectionView {
            let currentSize = icv.thumbnailSize().width + 10
            self.contentView?.cellDisplayMode = .iconified(size: CGSize(width: currentSize, height: currentSize * 0.875))
        }
        if let sav = self.selectedAssetsView {
            let currentSize = sav.thumbnailSize().width + 10
            sav.cellDisplayMode = .iconified(size: CGSize(width: currentSize, height: currentSize * 0.875))
        }
        self.populateContent()
    }
    
    func getItemsCountStr() -> String? {
        if self.currentAssetCollection == nil {
            return nil
        }
        if let cv = self.contentView, cv.itemCollectionView.numberOfSections > 0 {
            let totalCount = self.getItemsCount()
            let currentCount = cv.itemCollectionView.numberOfItems(inSection: 0)
            if totalCount == currentCount {
                return totalCount == 0 ? nil : (totalCount > 1 ? "\(totalCount) Items" : "1 Item")
            }
            else {
                return "\(currentCount) of \(totalCount) Items"
            }
        }
        return nil
    }
    
    func getItemsCount() -> Int {
        return self.assetCache.count
    }
    
    func addSelectedAsset(_ asset: PHAsset, thumbnail: UIImage) {
        let sAsset = AssetManager.persistence.createAssetCollectionAsset(thumbnail: thumbnail, asset: asset)
        if !sAsset.isVideoOrAudio() {
            sAsset.cropRect = photosService.detectFaceRect(inImage: thumbnail)
        }
        self.addSelectedAsset(sAsset)
    }

    func removeSelectedAsset(_ asset: FlexMediaPickerAsset) {
        self.removeImageSource(forID: asset.uuid)
        AssetManager.persistence.deleteImageAsset(withID: asset.uuid)
        self.populateSelectedAssetView()
    }

    private func removeImageSource(forID uuid: String) {
        var idx = 0
        for ims in self.imageSources {
            if ims.asset.uuid == uuid {
                self.imageSources.remove(at: idx)
                return
            }
            idx += 1
        }
        NSLog("Could not find image source to remove for uuid \(uuid)")
    }
    
    // MARK: - Internal View Model
    
    override open func populateContent() {
        super.populateContent()
        self.contentView?.removeAllSections()
        if self.assetCollections.count == 0 && self.currentAssetCollection == nil {
            return
        }
        if self.currentAssetCollection != nil && self.assetCache.count == 0 {
            return
        }
        BusyViewFactory.showBusyOverlay() {
            DispatchQueue.main.async {
                self.mainSecRef = self.contentView?.addSection(NSAttributedString(), height: 0, insets: UIEdgeInsetsMake(5, 10, 5, 10))
                if let ac = self.currentAssetCollection {
                    self.headerText = ac.localizedTitle
                    self.refreshView()
                    self.populateWithAssets()
                }
                else {
                    self.headerText = FlexMediaPickerConfiguration.mediaTitle
                    self.refreshView()
                    self.populateWithAssetCollections(self.assetCollections)
                    self.populateWithAssetCollections(self.smartAssetCollections)
                }
                self.contentView?.itemCollectionView.reloadData()
                self.contentView?.subHeaderText = self.getItemsCountStr()
            }
            BusyViewFactory.hideBusyOverlay()
        }
    }

    func populateWithAssets() {
        if let secRef = self.mainSecRef {
            for imageAsset in self.assetCache {
                let thumb = self.assetThumbnailCache.getImage(id: imageAsset.localIdentifier)
                let fitem = ImagesCollectionItem(reference: imageAsset.localIdentifier, icon: thumb)
                if thumb == nil {
                    let phi = UIImage(named: "imagePlaceholder")?.tint(FlexMediaPickerConfiguration.imagePlaceholderColor)
                    fitem.placeholderIcon = phi
                    fitem.imageViewLazyImageProvider = {
                        reference in
                        if let thumbnail = self.assetThumbnailCache.getImage(id: imageAsset.localIdentifier) {
                            return thumbnail
                        }
                        let thImageSize = CGSize(width: FlexMediaPickerConfiguration.thumbnailSize.width * 2, height: FlexMediaPickerConfiguration.thumbnailSize.height * 2)
                        let thumbnail = AssetManager.resolveAssets([imageAsset], size: thImageSize).first
                        if let th = thumbnail {
                            self.assetThumbnailCache.addImage(id: imageAsset.localIdentifier, image: th)
                        }
                        return thumbnail
                    }
                }
                fitem.canMoveItem = false
                fitem.imageViewFitting = .scaleToFit
                fitem.contentInteractionWillSelectItem = true
                fitem.itemSelectionActionHandler = {
                    if let icon = fitem.icon {
                        self.addSelectedAsset(imageAsset, thumbnail: icon)
                    }
                    fitem.isSelected = true
                    self.updateCellForItem(uuid: fitem.reference)
                }
                fitem.itemDeselectionActionHandler = {
                    if let asset = AssetManager.persistence.getAsset(forLocalIdentifier: imageAsset.localIdentifier) {
                        self.removeSelectedAsset(asset)
                    }
                    fitem.isSelected = false
                    self.updateCellForItem(uuid: fitem.reference)
                }
                fitem.subTitle = NSAttributedString(string: "")
                if imageAsset.mediaType == .audio || imageAsset.mediaType == .video {
                    let timeStr = Helper.stringFromTimeInterval(interval: imageAsset.duration)
                    fitem.secondarySubTitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.selectedMediaCaptionFont, color: FlexMediaPickerConfiguration.selectedMediaCaptionColor, text: timeStr)
                }
                if AssetManager.isAssetSelected(imageAsset) {
                    fitem.isSelected = true
                }
                self.contentView?.addItem(secRef, item: fitem)
            }
        }
    }
    
    func populateWithAssetCollections(_ collections: [PHAssetCollection]) {
        if let secRef = self.mainSecRef, let iconView = self.contentView as? ImagesCollectionView {
            for collection in collections {
                AssetManager.fetch(in: collection, fetchLimit: 1, { imageAssets in
                    if let imageAsset = imageAssets.first {
                        if let thumbnail = AssetManager.resolveAssets([imageAsset], size: iconView.thumbnailSize()).first {
                            let fitem = ImagesCollectionItem(reference: collection.localIdentifier, icon: thumbnail)
                            fitem.isGroup = true
                            fitem.subTitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.collectionCaptionFont, color: FlexMediaPickerConfiguration.collectionCaptionColor, text: collection.localizedTitle ?? "")
                            fitem.canMoveItem = false
                            fitem.imageViewFitting = .scaleToFit
                            fitem.contentInteractionWillSelectItem = true
                            fitem.autoDeselectCellAfter = .milliseconds(300)
                            fitem.itemSelectionActionHandler = {
                                self.fetchAssets(in: collection)
                            }
                            self.contentView?.addItem(secRef, item: fitem)
                            DispatchQueue.main.async {
                                self.contentView?.itemCollectionView.reloadData()
                            }
                        }
                    }
                })
            }
        }
    }
    
    // MARK: - Selected Assets View
    
    func populateSelectedAssetView() {
        self.applyAcceptEnabling()
        self.selectedAssetsView?.populate() {
            imageIndex in
            self.showImage(byIndex: imageIndex)
        }
    }
    
    private func applyAcceptEnabling() {
        DispatchQueue.main.async {
            var numApplicableSelected = 0
            let allSelectedAssets = AssetManager.persistence.getAllAssets()
            for sa in allSelectedAssets {
                if sa.isVideo() {
                    if FlexMediaPickerConfiguration.allowVideoSelection {
                        numApplicableSelected += 1
                    }
                }
                else if sa.isAudio() {
                    if FlexMediaPickerConfiguration.allowVoiceRecording {
                        numApplicableSelected += 1
                    }
                }
                else {
                    numApplicableSelected += 1
                }
            }
            self.acceptMI?.enabled = (numApplicableSelected > 0)
            if numApplicableSelected > 0 {
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
                let numImage = nImage?.addText(drawText: "\(numApplicableSelected)", font: FlexMediaPickerConfiguration.selectedMediaNumberFont)
                let maskPath = UIBezierPath(cgPath: mask.path!)
                let roundedImage = numImage?.maskImageWithPathAndCrop(maskPath)
                if let acceptImage = UIImage(named: "Accept_24pt")?.tint(FlexMediaPickerConfiguration.iconsColor) {
                    if let finalImage = roundedImage?.appendImage(acceptImage, margin: FlexMediaPickerConfiguration.selectedMediaAcceptedCountImageMargin) {
                        self.acceptMI?.thumbIcon = finalImage
                        self.rightViewMenu?.viewMenu?.thumbSize = finalImage.size
                    }
                }
            }
            self.selectedAssetsView?.showHide(hide: allSelectedAssets.count == 0)
            self.rightViewMenu?.viewMenu?.setNeedsLayout()
        }
    }
    
    private func getAcceptedAssets() -> [FlexMediaPickerAsset] {
        var returnableAssets: [FlexMediaPickerAsset] = []
        let allSelectedAssets = AssetManager.persistence.getAllAssets()
        for sa in allSelectedAssets {
            if sa.isVideo() {
                if FlexMediaPickerConfiguration.allowVideoSelection {
                    returnableAssets.append(sa)
                }
            }
            else if sa.isAudio() {
                if FlexMediaPickerConfiguration.allowVoiceRecording {
                    returnableAssets.append(sa)
                }
            }
            else {
                returnableAssets.append(sa)
            }
        }
        return returnableAssets
    }
    
    // MARK: - Fullscreen Preview
    
    func showImage(byIndex idx: Int) {
        // TODO: Stop recording before switching to viewer: ask to confirm
        
        if self.imageSlideshowView == nil {
            self.createImageSlideShowView()
        }
        if let issv = self.imageSlideshowView {
            self.voiceRecorderView?.showHide(hide: true)
            self.cameraView?.showHide(hide: true)
            issv.isHidden = false
            issv.imageSlideshow?.setImageInputs(self.imageSources)
            issv.setCurrentPage(idx, animated: false)
        }
    }
    
    private func createImageSlideShowView() {
        self.imageSlideshowView = ImageSlideShowView(frame: self.view.bounds)
        if let issv = self.imageSlideshowView {
            issv.styleColor = FlexMediaPickerConfiguration.styleColor
            issv.imageSlideshow?.setImageInputs(self.imageSources)
            self.view.insertSubview(issv, at: 1)
            issv.closeHandler = {
                self.imageSlideshowView?.isHidden = true
            }
            issv.hideViewElementsHandler = { hide in
                self.selectedAssetsView?.showHide(hide: hide)
            }
            issv.didGetPhoto = {
                image in
                self.addNewImage(image, location: nil)
            }
            issv.removeOrTrashSelectedItem = {
                asset in
                self.removeSelectedAsset(asset)
            }
            issv.updateImageCroppingHandler = {
                self.populateSelectedAssetView()
            }
            issv.hideViewElements(hide: true)
        }
    }
    
    // MARK: - Locations

    private func addCurrentLocationAsImage() {
        locationService.getCurrentLocationAsImage() {
            image in
            self.addNewImage(image, location: nil)
        }
    }
    
    // MARK: - Helper
    
    func updateCellForItem(uuid: String) {
        DispatchQueue.main.async {
            if let ip = self.contentView?.getIndexPathForItem(uuid) {
                if let cell = self.contentView?.itemCollectionView.cellForItem(at: ip) {
                    cell.setNeedsLayout()
                }
            }
        }
    }
}
