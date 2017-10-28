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

class SelectedAssetsCollectionView: ImagesCollectionView {}

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

    private var assetThumbnailCache = ImageCache()
    private var assetCollections: [PHAssetCollection] = []
    private var smartAssetCollections: [PHAssetCollection] = []
    private var assetCache: [PHAsset] = []
    private var currentAssetCollection: PHAssetCollection?

    private var imageSlideshowView: ImageSlideShowView?

    private var cameraView: CameraView?
    
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

        let ccvcApp = FlexBaseCollectionViewCell.appearance(whenContainedInInstancesOf: [ImagesCollectionView.self])
        ccvcApp.styleColor = .clear
        
        let stccApp = FlexPrimaryLabel.appearance(whenContainedInInstancesOf: [FlexFooterView.self, ImagesCollectionView.self])
        stccApp.labelTextAlignment = .center
        
        let ccApp = ImagesCollectionCell.appearance()
        ccApp.imageViewStyle = FlexShapeStyle(style: .roundedFixed(cornerRadius: 5))
        ccApp.selectedStyleColor = FlexMediaPickerConfiguration.selectedItemColor
        
        let cellApp = FlexCellView.appearance(whenContainedInInstancesOf: [ImagesCollectionView.self])
        cellApp.style = FlexShapeStyle(style: .roundedFixed(cornerRadius: 5))

        let footerApp = MainMediaControlPanel.appearance(whenContainedInInstancesOf: [ImagesCollectionView.self])
        footerApp.styleColor = FlexMediaPickerConfiguration.footerPanelColor

        let cfooterApp = CameraMediaControlPanel.appearance(whenContainedInInstancesOf: [CameraView.self])
        cfooterApp.styleColor = FlexMediaPickerConfiguration.footerPanelColor
        
        self.contentView = ImageMediaCollectionView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.contentView?.headerFooterAdaptToMenu = false
        self.contentView?.registerCell(ImagesCollectionItem.self, cellClass: ImagesCollectionCell.self)
        self.view.addSubview(self.contentView!)
        self.applyCollectionViewDefaultStyling(collectionView: self.contentView!)
        self.contentView?.header.caption.labelFont = FlexMediaPickerConfiguration.headerFont

        self.contentView?.header.subCaption.labelTextAlignment = .center
        self.contentView?.header.subCaption.labelFont = FlexMediaPickerConfiguration.headerSubCaptionFont
        self.contentView?.header.subCaption.labelTextColor = FlexMediaPickerConfiguration.headerTextColor

        self.createIconMenu(width: 50, menuIconSize: 24)
        self.rightViewMenu?.createAcceptIconMenuItem()
        self.rightViewMenu?.menuSelectionHandler = {
            type in
            if type == .accept {
                self.convertSelectedVideoAssets {
                    let aa = self.getAcceptedAssets()
                    self.mediaAcceptedHandler?(aa)
                }
            }
        }
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
            sav.registerCell(ImagesCollectionItem.self, cellClass: ImagesCollectionCell.self)
            (sav.itemCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
            sav.centerCellsHorizontally = true
            sav.styleColor = FlexMediaPickerConfiguration.selectedAssetsStyleColor
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
                case .microphone:
                    break
                case .cameraTake:
                    break
                case .videocamMode:
                    break
                case .videocamTake:
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
            self.selectedAssetsView?.setNeedsLayout()
        }
        else {
            self.cameraView?.headerPosition = .top
            (self.selectedAssetsView?.itemCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
            self.selectedAssetsView?.setNeedsLayout()
        }
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
            sav.frame = self.selectedAssetsViewRect()
        }
        else {
            self.contentView?.viewMargins = UIEdgeInsetsMake(0, 0, 0, 0)
        }

        var resBounds = self.view.bounds.offsetBy(dx: 0, dy: UIApplication.shared.statusBarFrame.height * 0.5).insetBy(dx: 0, dy: UIApplication.shared.statusBarFrame.height * 0.5)
        resBounds = CGRect(origin: resBounds.origin, size: CGSize(width: resBounds.size.width, height: resBounds.size.height-tabbarSize))
        self.contentView?.frame = resBounds
        
        let camRect = self.view.bounds
        self.cameraView?.frame = camRect
        self.cameraView?.setNeedsLayout()
        
        self.imageSlideshowView?.frame = self.view.bounds
        
        super.refreshView()
    }
    
    private func selectedAssetsViewRect() -> CGRect {
        if self.cameraView != nil && (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight) {
            return CGRect(x: self.view.bounds.size.width - (120 + 64), y: 0, width: 120, height: self.view.bounds.size.height)
        }
        return CGRect(x: 0, y: self.view.bounds.size.height - (120 + 64), width: self.view.bounds.size.width, height: 120)
    }
    
    // MARK: - Item Access
    
    func checkStatus() {
        let currentStatus = PHPhotoLibrary.authorizationStatus()
        guard currentStatus != .authorized else {
            self.permissionGranted()
            return
        }
        
        if currentStatus == .notDetermined { self.closeView() }
        
        PHPhotoLibrary.requestAuthorization { (authorizationStatus) -> Void in
            DispatchQueue.main.async {
                if authorizationStatus == .denied {
                    self.presentAskPermissionAlert()
                } else if authorizationStatus == .authorized {
                    self.permissionGranted()
                }
            }
        }
    }
    
    func presentAskPermissionAlert() {
        let alertController = UIAlertController(title: FlexMediaPickerConfiguration.requestPermissionTitle, message: FlexMediaPickerConfiguration.requestPermissionMessage, preferredStyle: .alert)
        
        let alertAction = UIAlertAction(title: FlexMediaPickerConfiguration.OKButtonTitle, style: .default) { _ in
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: FlexMediaPickerConfiguration.cancelButtonTitle, style: .cancel) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(alertAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
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
        if FlexMediaPickerConfiguration.allowVideoSelection {
            let aAssets = self.getAcceptedAssets()
            var assetsToConvert: [FlexMediaPickerAsset] = []
            for aa in aAssets {
                if aa.isVideo() {
                    assetsToConvert.append(aa)
                }
            }
            
            BusyViewFactory.showProgressOverlay(onView: nil, completionHandler: {
                var idx = 1
                let assetsConvertCount = assetsToConvert.count
                let queue = TaskQueue()
                
                for _ in 0..<assetsConvertCount {
                    queue.tasks +=~ { result, next in
                        BusyViewFactory.updateProgress(progress: 0, upperLabel: "Converting Videos", lowerLabel: "\(idx) of \(assetsConvertCount)")

                        if let assetToConvert = assetsToConvert.first != nil ? assetsToConvert.removeFirst() : nil {
                            AssetManager.reencodeVideo(forMediaAsset: assetToConvert, progressHandler: { progress in
                                BusyViewFactory.updateProgress(progress: progress, upperLabel: "Converting Videos", lowerLabel: "\(idx) of \(assetsConvertCount)")
                            }, completedURLHandler: { url in
                                AssetManager.storeVideo(forURL: url, completion: { _ in
                                    NSLog("re-encoded video stored to Photos (as test)")
                                    next(nil)
                                })
                            })
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
        else {
            completedHandler()
        }
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
        let thImageSize = FlexMediaPickerConfiguration.thumbnailSize
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
        if let secRef = self.mainSecRef, let iconView = self.contentView as? ImagesCollectionView {
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
                        let thumbnail = AssetManager.resolveAssets([imageAsset], size: iconView.thumbnailSize()).first
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
                }
                fitem.itemDeselectionActionHandler = {
                    if let asset = AssetManager.persistence.getAsset(forLocalIdentifier: imageAsset.localIdentifier) {
                        self.removeSelectedAsset(asset)
                    }
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
        DispatchQueue.main.async {
            self.applyAcceptEnabling()
            if let sav = self.selectedAssetsView {
                sav.removeAllSections()
                let savSecRef = sav.addSection()
                let allSelectedAssets = AssetManager.persistence.getAllAssets()
                var idx = 0
                for selAsset in allSelectedAssets {
                    let ref = selAsset.asset?.localIdentifier ?? UUID().uuidString
                    let fitem = ImagesCollectionItem(reference: ref, icon: selAsset.thumbnail)
                    fitem.canMoveItem = false
                    fitem.imageViewFitting = .scaleToFit
                    fitem.contentInteractionWillSelectItem = true
                    fitem.autoDeselectCellAfter = .milliseconds(300)
                    fitem.imageIndex = idx
                    fitem.itemSelectionActionHandler = {
                        self.showImage(byIndex: fitem.imageIndex)
                    }
                    sav.addItem(savSecRef, item: fitem)
                    idx += 1
                }
                sav.itemCollectionView.reloadData()
                if allSelectedAssets.count > 0 && sav.isHidden == true {
                    self.showSelectedAssetView()
                }
                if allSelectedAssets.count == 0 && sav.isHidden == false {
                    self.hideSelectedAssetView()
                }
            }
        }
    }
    
    private func applyAcceptEnabling() {
        var numApplicableSelected = 0
        // TODO: must be extended to allow VoiceRecordings
        let allSelectedAssets = AssetManager.persistence.getAllAssets()
        for sa in allSelectedAssets {
            if sa.isVideo() {
                if FlexMediaPickerConfiguration.allowVideoSelection {
                    numApplicableSelected += 1
                }
            }
            else {
                numApplicableSelected += 1
            }
        }
        self.rightViewMenu?.viewMenuItems[0].enabled = (numApplicableSelected > 0)
        self.rightViewMenu?.viewMenu?.setNeedsLayout()
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
            else {
                returnableAssets.append(sa)
            }
        }
        return returnableAssets
    }
    
    func showSelectedAssetView() {
        if let sav = self.selectedAssetsView, !sav.isHidden {
            return
        }
        self.selectedAssetsView?.alpha = 0
        self.selectedAssetsView?.isHidden = false
        self.refreshView()
        UIView.animate(withDuration: 0.3, animations: {
            self.selectedAssetsView?.alpha = 1
        })
    }

    func hideSelectedAssetView() {
        if let sav = self.selectedAssetsView, sav.isHidden {
            return
        }
        self.selectedAssetsView?.alpha = 1
        UIView.animate(withDuration: 0.3, animations: {
            self.selectedAssetsView?.alpha = 0
        }) { _ in
            self.selectedAssetsView?.isHidden = true
            self.refreshView()
        }
    }
    
    // MARK: - Fullscreen Preview
    
    func showImage(byIndex idx: Int) {
        if self.imageSlideshowView == nil {
            self.createImageSlideShowView()
        }
        if let issv = self.imageSlideshowView {
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
            issv.hideViewElements(hide: true)
        }
    }
    
    // MARK: - Helper
    
    func updateCellForItem(uuid: String) {
        if let ip = self.contentView?.getIndexPathForItem(uuid) {
            if let cell = self.contentView?.itemCollectionView.cellForItem(at: ip) {
                cell.setNeedsLayout()
            }
        }
    }
}
