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
import StyledOverlay
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
            self.acceptSelectedAssets()
        })
        self.contentView?.addMenu(self.rightViewMenu!)
        self.acceptMI?.enabled = false
 
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
        
        self.setupSelectedAssetsView()
        
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
        self.voiceRecorderView?.closeView()
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

        if let sav = self.selectedAssetsView, !sav.isHidden {
            self.baseViewMargins = UIEdgeInsetsMake(0, 0, 120, 0)
        }
        else {
            self.baseViewMargins = .zero
        }
        self.selectedAssetsView?.frame = self.selectedAssetsViewRect()
        
        self.cameraView?.frame = self.view.bounds
        self.imageSlideshowView?.frame = self.view.bounds
        self.voiceRecorderView?.frame = self.view.bounds

        if #available(iOS 11, *) {
            self.contentView?.frame = self.view.bounds

            var cinsets:UIEdgeInsets = .zero
            if UIDevice.current.orientation == .landscapeRight {
                cinsets = UIEdgeInsetsMake(0, 0, 0, self.view.safeAreaInsets.right)
            }
            else if UIDevice.current.orientation != .landscapeLeft {
                cinsets = UIEdgeInsetsMake(self.view.safeAreaInsets.top, 0, self.view.safeAreaInsets.bottom, 0)
            }
            self.cameraView?.viewElementsInsets = cinsets

            let insets = UIEdgeInsetsMake(self.view.safeAreaInsets.top, 0, self.view.safeAreaInsets.bottom, 0)
            self.imageSlideshowView?.viewElementsInsets = insets
            self.voiceRecorderView?.viewElementsInsets = insets
        }
        else {
            var tabbarSize: CGFloat = 0
            if let tbc = self.tabBarController {
                tabbarSize = tbc.tabBar.isHidden ? 0 : tbc.tabBar.bounds.size.height - 3
            }

            var resBounds = self.view.bounds.offsetBy(dx: 0, dy: UIApplication.shared.statusBarFrame.height * 0.5).insetBy(dx: 0, dy: UIApplication.shared.statusBarFrame.height * 0.5)
            resBounds = CGRect(origin: resBounds.origin, size: CGSize(width: resBounds.size.width, height: resBounds.size.height-tabbarSize))
            self.contentView?.frame = resBounds
        }
        self.cameraView?.setNeedsLayout()
        self.voiceRecorderView?.setNeedsLayout()

        super.refreshView()
    }
    
    private func selectedAssetsViewRect() -> CGRect {
        let savHeight = FlexMediaPickerConfiguration.selectedMediaPanelHeight
        let fHeight = FlexMediaPickerConfiguration.footerHeight
        var sbounds = self.view.bounds
        if self.cameraView != nil && UIDevice.current.orientation == .landscapeRight {
            if #available(iOS 11, *) {
                sbounds = CGRect(x: sbounds.minX + self.view.safeAreaInsets.left, y: sbounds.minY, width: sbounds.width - (self.view.safeAreaInsets.left + self.view.safeAreaInsets.right), height: sbounds.height)
            }
            return CGRect(x: sbounds.size.width - (savHeight + fHeight), y: 0, width: savHeight, height: sbounds.size.height)
        }
        if self.cameraView != nil && UIDevice.current.orientation == .landscapeLeft {
            return CGRect(x: sbounds.size.width - (savHeight + fHeight), y: 0, width: savHeight, height: sbounds.size.height)
        }
        // Portrait mode
        if #available(iOS 11, *) {
            sbounds = CGRect(x: sbounds.minX, y: sbounds.minY, width: sbounds.width, height: sbounds.height - self.view.safeAreaInsets.bottom)
        }
        return CGRect(x: 0, y: sbounds.size.height - (savHeight + fHeight), width: sbounds.size.width, height: savHeight)
    }
    
    // MARK: - Camera View
    
    private func showCameraView() {
        self.cameraView?.removeFromSuperview()

        self.cameraView = CameraView(frame: self.view.bounds)
        self.view.insertSubview(self.cameraView!, at: 1)
        self.cameraView?.headerFooterAdaptToMenu = false
        self.cameraView?.displayView()
        self.cameraView?.didGetPhoto = {
            image, location in
            DispatchQueue.main.async {
                self.addNewImage(image, location: location)
            }
        }
        self.cameraView?.cancelCameraViewHandler = {
            DispatchQueue.main.async {
                self.cameraView?.removeFromSuperview()
                self.cameraView = nil
            }
        }
        self.cameraView?.didRecordVideo = {
            mpa in
            DispatchQueue.main.async {
                self.addSelectedAsset(mpa)
            }
        }
        self.layoutSupplementaryViews(to: self.view.bounds.size)
    }
    
    // MARK: - Voice Recording
    
    private func showVoiceRecorderView() {
        self.voiceRecorderView?.removeFromSuperview()

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
            AlertViewFactory.showFailAlert(title: FlexMediaPickerConfiguration.recordingFailedTitle, message: FlexMediaPickerConfiguration.recordingFailedMessage, iconName: FlexMediaPickerConfiguration.alertIconName)
        }
        self.layoutSupplementaryViews(to: self.view.bounds.size)
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
        let aAssets = AssetManager.getAcceptedAssets()
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
                                assetToConvert.convertedURL = url
                                next(nil)
                            })
                        }
                        else if assetToConvert.isAudio() {
                            AssetManager.cropAudio(forMediaAsset: assetToConvert, progressHandler: { progress in
                                BusyViewFactory.updateProgress(progress: progress, upperLabel: "Converting Audio", lowerLabel: "\(idx) of \(assetsConvertCount)")
                            }, completedURLHandler: { url in
                                assetToConvert.convertedURL = url
                                next(nil)
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

    private func addNewLocation(_ thumbnail: UIImage, location: CLLocation) {
        let locAsset = AssetManager.persistence.createLocationAsset(thumbnail: thumbnail, location: location)
        self.addSelectedAsset(locAsset)
    }

    private func addSelectedAsset(_ asset: FlexMediaPickerAsset) {
        self.imageSlideshowView?.addAsset(asset)
        self.populateSelectedAssetView(focusOnLastItem: true)
        if !FlexMediaPickerConfiguration.allowMultipleSelection {
            if AssetManager.persistence.numberOfAssets() >= FlexMediaPickerConfiguration.numberItemsAllowed {
                self.selectedAssetsView?.showHide(hide: false) {
                    self.refreshView()
                }
                self.showImage(byIndex: AssetManager.persistence.numberOfAssets()-1)
            }
        }
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
        AssetManager.persistence.deleteImageAsset(withID: asset.uuid)
        self.populateSelectedAssetView(focusOnLastItem: true)
        if let li = asset.asset?.localIdentifier {
            if let item = self.contentView?.getItemForReference(li) {
                item.isSelected = false
                self.contentView?.deselectItem(item.reference)
                self.updateCellForItem(uuid: item.reference)
            }
        }
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
        self.contentView?.itemCollectionView.reloadData()
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
    
    func setupSelectedAssetsView() {
        // The selected assets will be shown in a sub view
        self.selectedAssetsView = SelectedAssetsCollectionView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if let sav = self.selectedAssetsView {
            self.applyCollectionViewDefaultStyling(collectionView: sav)
            sav.styleColor = FlexMediaPickerConfiguration.selectedMediaStyleColor
            (sav.itemCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
            sav.centerCellsHorizontally = true
            sav.isHidden = true
            sav.deleteOrRemoveItemHandler = {
                assetRef in
                if let asset = AssetManager.persistence.getAsset(forID: assetRef) {
                    self.removeSelectedAsset(asset)
                    self.imageSlideshowView?.removeAsset(byID: assetRef)
                }
            }
            self.view.addSubview(sav)
        }
    }
    
    func populateSelectedAssetView(focusOnLastItem: Bool = false, focusOnItemByIndex: String? = nil) {
        self.applyAcceptEnabling()
        self.selectedAssetsView?.populate(focusOnLastItem: focusOnLastItem, focusOnItemByIndex: focusOnItemByIndex) {
            imageIndex in
            self.showImage(byIndex: imageIndex)
        }
    }
    
    private func cleanupTakeViews() {
        self.voiceRecorderView?.removeFromSuperview()
        self.voiceRecorderView = nil
        self.cameraView?.removeFromSuperview()
        self.cameraView = nil
    }
    
    private func applyAcceptEnabling() {
        DispatchQueue.main.async {
            let numApplicableSelected = AssetManager.getAcceptableAssetCount()
            self.acceptMI?.enabled = (numApplicableSelected > 0)
            if numApplicableSelected > 0 {
                if let aicImage = Helper.getAcceptedAssetCountIcon(acceptableAssetCount: numApplicableSelected) {
                    self.acceptMI?.thumbIcon = aicImage
                    self.rightViewMenu?.viewMenu?.thumbSize = aicImage.size
                }
            }
            self.selectedAssetsView?.showHide(hide: AssetManager.persistence.numberOfAssets() == 0) {
                self.refreshView()
            }
            self.rightViewMenu?.viewMenu?.setNeedsLayout()
        }
    }
    
    private func acceptSelectedAssets() {
        self.convertSelectedVideoAssets {
            let aa = AssetManager.getAcceptedAssets()
            self.mediaAcceptedHandler?(aa)
        }
    }
    
    // MARK: - Fullscreen Preview
    
    func showImage(byIndex idx: Int) {
        var shouldConfirm = false
        if let cv = self.cameraView, cv.cameraMan.isCapturing {
            cv.confirmedClose(confirmationHandler: { confirmed in
                self.showImageConfirmed(byIndex: idx)
            })
            shouldConfirm = true
        }
        if let rv = self.voiceRecorderView, rv.micMan.isRecording {
            rv.confirmedClose(confirmationHandler: { confirmed in
                self.showImageConfirmed(byIndex: idx)
            })
            shouldConfirm = true
        }
        if !shouldConfirm {
            self.showImageConfirmed(byIndex: idx)
        }
    }
    
    private func showImageConfirmed(byIndex idx: Int) {
        if self.imageSlideshowView == nil {
            self.createImageSlideShowView()
        }
        if let issv = self.imageSlideshowView {
            self.cleanupTakeViews()
            issv.isHidden = false
            issv.setAssets(AssetManager.persistence.getAllAssets())
            issv.setCurrentPage(idx, animated: false)
        }
    }
    
    private func createImageSlideShowView() {
        self.imageSlideshowView = ImageSlideShowView(frame: self.view.bounds)
        if let issv = self.imageSlideshowView {
            issv.styleColor = FlexMediaPickerConfiguration.styleColor
            self.view.insertSubview(issv, at: 1)
            issv.closeHandler = {
                self.imageSlideshowView?.removeFromSuperview()
                self.imageSlideshowView = nil
            }
            issv.hideViewElementsHandler = { hide in
                self.selectedAssetsView?.showHide(hide: hide) {
                    self.refreshView()
                }
            }
            issv.didGetPhoto = {
                image in
                self.addNewImage(image, location: nil)
            }
            issv.removeOrTrashLastItem = {
                if let asset = AssetManager.persistence.getAllAssets().last {
                    self.removeSelectedAsset(asset)
                }
            }
            issv.updateImageCroppingHandler = {
                self.populateSelectedAssetView(focusOnItemByIndex: issv.currentAsset?.uuid)
            }
            issv.focusedSelectedItem = {
                asset in
                self.selectedAssetsView?.focusOnItem(withReference: asset.uuid)
            }
            issv.avTimingOffsetsChangedHandler = {
                asset in
                self.selectedAssetsView?.refreshItem(withReference: asset.uuid)
            }
            issv.acceptSelectedAssetsHandler = self.acceptSelectedAssets
            issv.hideViewElements(hide: true)
        }
    }
    
    // MARK: - Locations

    private func addCurrentLocationAsImage() {
        BusyViewFactory.showBusyOverlay() {
            locationService.getCurrentLocationAsImage() {
                image, location in
                BusyViewFactory.hideBusyOverlay() {
                    self.addNewLocation(image, location: location)
                }
            }
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
