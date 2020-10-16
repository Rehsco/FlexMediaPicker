//
//  ImageSlideShowView.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 30.09.2017.
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
import ImageSlideshow
import AVFoundation
import Player
import StyledOverlay
import FlexImageCropView

class ImageSlideShowView: CommonFlexView, PlayerDelegate, PlayerPlaybackDelegate, AVAudioPlayerDelegate {
    
    private var player: Player?
    private var audioPlayer: AVAudioPlayer?

    private var cropView: ImageCropView?
    
    private var currentImageSource: ImageAssetImageSource?

    var currentAsset: FlexMediaPickerAsset?
    private var movieAsset: AVURLAsset?
    private var meterTimer: Timer?

    private var assetInfoLabel: FlexLabel?
    private var assetWarningLabel: FlexTextView?

    private var timeSliderPanel: VideoTimeSliderView?
    private let posUpdateTimer = PositionUpdateTimer()
    private var shouldUpdateTimeOffset: Bool = false
    
    private var cropMI: FlexMenuItem?
    private var acceptMI: FlexMenuItem?

    private var overlayMaskLayer: CALayer?
    
    private var imageSlideshow: ImageSlideshow?
    
    /// The offsets are [0..1]
    var minimumAVOffset: Double = 0
    var currentAVOffset: Double = 0
    var maximumAVOffset: Double = 1

    /// Handlers
    
    var closeHandler: (()->Void)?
    var acceptSelectedAssetsHandler: (()->Void)?
    var hideViewElementsHandler: ((Bool)->Void)?
    var didGetPhoto: ((UIImage)->Void)?
    var removeOrTrashLastItem: (()->Void)?
    var focusedSelectedItem: ((FlexMediaPickerAsset)->Void)?
    var avTimingOffsetsChangedHandler: ((FlexMediaPickerAsset)->Void)?
    var updateImageCroppingHandler: (()->Void)?

    deinit {
        NSLog("\(#function) Media Viewer")
        self.finalCleanup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    private var videoControlPanel = VideoPlaybackControlPanel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    override var footer: FlexFooterView {
        return self.videoControlPanel
    }
    
    private func setupView() {
        self.imageSlideshow = ImageSlideshow(frame: self.bounds)
        self.imageSlideshow?.zoomEnabled = true
        self.imageSlideshow?.preload = .fixed(offset: 1)
        self.imageSlideshow?.circular = true
        self.imageSlideshow?.pageIndicator = nil
        
        self.imageSlideshow?.willBeginDragging = {
            self.player?.view.isHidden = true
        }
        
        self.timeSliderPanel = VideoTimeSliderView(frame: CGRect(x: 0, y: FlexMediaPickerConfiguration.headerHeight, width: self.bounds.size.width, height: FlexMediaPickerConfiguration.timeSliderPanelHeight))
        self.timeSliderPanel?.videoTimeOffsetChangeHandler = {
            offset in
            self.currentAVOffset = offset
            self.userDidUpdateTimeOffsets()
            if self.isCurrentAssetAVideo() {
                self.updateVideoTime(toOffset: offset, shouldUpdateFrameStepper: true, shouldUpdateTimeSlider: false)
            }
            else {
                self.updateAudioTime(toOffset: offset, shouldUpdateTimeSlider: false)
            }
        }
        self.timeSliderPanel?.videoTimeMinOffsetChangeHandler = {
            offset in
            self.minimumAVOffset = offset
            self.userDidUpdateTimeOffsets()
            if let ca = self.currentAsset {
                self.avTimingOffsetsChangedHandler?(ca)
            }
            if self.isCurrentAssetAVideo() {
                self.updateFrameStepper()
            }
        }
        self.timeSliderPanel?.videoTimeMaxOffsetChangeHandler = {
            offset in
            self.maximumAVOffset = offset
            self.userDidUpdateTimeOffsets()
            if let ca = self.currentAsset {
                self.avTimingOffsetsChangedHandler?(ca)
            }
            if self.isCurrentAssetAVideo() {
                self.updateFrameStepper()
            }
        }
        self.addSubview(self.timeSliderPanel!)
        
        self.headerText = " "
        self.headerSize = FlexMediaPickerConfiguration.headerHeight
        self.header.styleColor = FlexMediaPickerConfiguration.headerColor

        self.assetInfoLabel = FlexLabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.assetInfoLabel?.labelTextColor = FlexMediaPickerConfiguration.headerTextColor
        self.assetInfoLabel?.labelFont = FlexMediaPickerConfiguration.headerFont
        self.assetInfoLabel?.labelTextAlignment = .center
        self.header.addSubview(self.assetInfoLabel!)
        
        self.assetWarningLabel = FlexTextView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.assetWarningLabel?.textView.textColor = FlexMediaPickerConfiguration.warningLabelTextColor
        self.assetWarningLabel?.textView.font = FlexMediaPickerConfiguration.warningLabelFont
        self.assetWarningLabel?.textView.textAlignment = .center
        self.assetWarningLabel?.isHidden = true
        self.assetWarningLabel?.textView.backgroundColor = .clear
        self.assetWarningLabel?.textView.isEditable = false
        self.assetWarningLabel?.textView.isSelectable = false
        self.addSubview(self.assetWarningLabel!)
        
        self.createBackOrCloseLeftMenu() {
            if !FlexMediaPickerConfiguration.allowMultipleSelection && FlexMediaPickerAssetManager.getAcceptableAssetCount() >= FlexMediaPickerConfiguration.numberItemsAllowed {
                StyledMenuPopoverFactory.confirmation(title: FlexMediaPickerConfiguration.removeItemTitle, subTitle: FlexMediaPickerConfiguration.removeItemMessage, buttonText: FlexMediaPickerConfiguration.removeItemButtonText, iconName: FlexMediaPickerConfiguration.queryIconName, configuration: FlexMediaPickerStyling.getPopoverViewAppearance(), confirmationResult: { proceed in
                    if proceed {
                        self.removeOrTrashLastItem?()
                        self.closeView()
                    }
                })
            }
            else {
                self.closeView()
            }
        }
        
        self.rightViewMenu = CommonIconViewMenu(size: CGSize(width: 160, height: 36), hPos: .right, vPos: .header, menuIconSize: 24)
        self.cropMI = self.rightViewMenu?.createIconMenuItem(imageName: "", selectedImageName: "crop", iconSize: 24, selectionHandler: {
            if let asset = self.currentAsset, let image = FlexMediaPickerAssetManager.persistence.imageFromAsset(withID: asset.uuid) {
                self.cropView = ImageCropView(frame: UIScreen.main.bounds, image: image, cropRect: asset.cropRect)
                self.cropView?.imageCroppedHandler = {
                    cropRect in
                    asset.cropRect = cropRect
                    // TODO: Update views!
                    self.updateImageCroppingHandler?()
                }
                if let tvc = self.getTopViewController() {
                    tvc.view.addSubview(self.cropView!)
                }
            }
        })
        self.acceptMI = self.rightViewMenu?.createIconMenuItem(imageName: "Accept", selectionHandler: {
            self.acceptSelectedAssetsHandler?()
        })
        self.addMenu(self.rightViewMenu!)
        
        self.footerSize = FlexMediaPickerConfiguration.footerHeight
        self.footer.styleColor = FlexMediaPickerConfiguration.footerPanelColor
        
        let tgr = UITapGestureRecognizer(target: self, action: #selector(self.imageSlideshowTap(_:)))
        self.addGestureRecognizer(tgr)
        
        self.imageSlideshow?.currentPageChanged = {
            index in
            self.updateCurrentPage(toIndex: index)
        }
        
        self.applyControlsEnabling()

        // Video Playback
        
        if let tvc = self.getTopViewController() {
            self.player = Player()
            self.player?.autoplay = false
            self.player?.playerDelegate = self
            self.player?.playbackDelegate = self
            self.player?.view.frame = self.bounds
            self.player?.view.backgroundColor = FlexMediaPickerConfiguration.styleColor
            
            tvc.addChild(self.player!)
            self.player?.didMove(toParent: tvc)
            
            let nextGR = UISwipeGestureRecognizer(target: self, action: #selector(self.playerSwipeNext(_:)))
            nextGR.direction = .left
            let prevGR = UISwipeGestureRecognizer(target: self, action: #selector(self.playerSwipePrev(_:)))
            prevGR.direction = .right
            self.player?.view.addGestureRecognizer(nextGR)
            self.player?.view.addGestureRecognizer(prevGR)
        }
        
        self.insertSubview(player!.view, at: 1)
        self.insertSubview(self.imageSlideshow!, at: 2)
        
        if let fv = self.footer as? VideoPlaybackControlPanel {
            fv.frameStepperChangeHandler = {
                newFrame in
                self.currentAsset?.currentFrame = newFrame
                let offset = newFrame / self.getMaxFrame()
                self.currentAVOffset = offset
                self.userDidUpdateTimeOffsets()
                self.updateVideoTime(toOffset: offset, shouldUpdateFrameStepper: false, shouldUpdateTimeSlider: true)
            }
            fv.playPressedHandler = {
                shouldPlay in
                if let pp = self.player, self.isCurrentAssetAVideo() {
                    if shouldPlay {
                        if pp.view.superview == nil {
                            pp.view.backgroundColor = self.styleColor
                        }
                        pp.playFromCurrentTime()
                    }
                    else {
                        self.updateImageToVideoFrame()
                        pp.pause()
                    }
                }
                else if let ap = self.audioPlayer {
                    if shouldPlay {
                        ap.play()
                    }
                    else {
                        ap.pause()
                    }
                }
            }
            fv.snapshotPressedHandler = {
                self.currentImageSource?.imageFromVideoURL() { image in
                    if let image = image {
                        self.didGetPhoto?(image)
                    }
                }
            }
            fv.setupMenu(in: self)
        }
        
        self.startPositionUpdateNotification()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.scrollviewBeginsZoom(_:)), name: Notification.Name(rawValue: ScrollViewNotifications.ScrollViewBeginsZoom), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.scrollviewEndsZoom(_:)), name: Notification.Name(rawValue: ScrollViewNotifications.ScrollViewEndsZoom), object: nil)
    }
    
    open func setAssets(_ assets: [FlexMediaPickerAsset]) {
        var imageSources: [ImageAssetImageSource] = []
        for asset in assets {
            let ias = ImageAssetImageSource(asset: asset)
            imageSources.append(ias)
        }
        self.imageSlideshow?.setImageInputs(imageSources)
        self.applyControlsEnabling()
    }
    
    open func addAsset(_ asset: FlexMediaPickerAsset) {
        let ias = ImageAssetImageSource(asset: asset)
        if let iss = self.imageSlideshow {
            var sources = iss.images
            sources.append(ias)
            iss.setImageInputs(sources)
            self.applyControlsEnabling()
        }
    }
    
    open func removeAsset(byID id: String) {
        DispatchQueue.main.async {
            if let iss = self.imageSlideshow {
                var sources = iss.images
                if sources.count < 2 {
                    self.closeView()
                }
                else if let pageIdx = self.getPageIndexForAsset(withID: id) {
                    let cp = iss.currentPage
                    sources.remove(at: pageIdx)
                    iss.setImageInputs(sources)
                    let np: Int
                    if cp >= pageIdx {
                        if cp > 0 {
                            np = cp - 1
                        }
                        else {
                            np = 0
                        }
                    }
                    else {
                        np = cp % sources.count
                    }
                    iss.setCurrentPage(np, animated: true)
                    self.updateCurrentPage(toIndex: np)
                    self.applyControlsEnabling()
                }
            }
        }
    }
    
    private func getPageIndexForAsset(withID id: String) -> Int? {
        if let iss = self.imageSlideshow {
            var pageIdx = 0
            for src in iss.images {
                if let asrc = src as? ImageAssetImageSource {
                    if asrc.asset.uuid == id {
                        return pageIdx
                    }
                    pageIdx += 1
                }
            }
        }
        return nil
    }
    
    private func finalCleanup() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ScrollViewNotifications.ScrollViewBeginsZoom), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ScrollViewNotifications.ScrollViewEndsZoom), object: nil)
        
        self.posUpdateTimer.stop()
    }
    
    @objc func scrollviewBeginsZoom(_ sender: Any) {
        self.player?.view.isHidden = true
    }

    @objc func scrollviewEndsZoom(_ sender: Any) {
        if let ass = self.currentAsset, ass.isVideoOrAudio() {
            self.player?.view.isHidden = false
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.imageSlideshow?.isHidden = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageSlideshow?.frame = self.bounds
        self.player?.view.frame = self.bounds
        self.assetInfoLabel?.frame = self.header.bounds
        self.cropView?.frame = self.bounds
        var sOffset: CGFloat = 0
        if #available(iOS 11, *) {
            sOffset = self.safeAreaInsets.top
            self.cropView?.viewElementsInsets = UIEdgeInsets.init(top: self.safeAreaInsets.top, left: 0, bottom: self.safeAreaInsets.bottom, right: 0)
        }
        self.timeSliderPanel?.frame = CGRect(x: 0, y: FlexMediaPickerConfiguration.headerHeight + sOffset, width: self.bounds.size.width, height: FlexMediaPickerConfiguration.timeSliderPanelHeight)
        let warnBaseRect = CGRect(x: self.header.bounds.minX, y: self.header.bounds.minY, width: self.header.bounds.width, height: self.header.bounds.height * 2.0)
        let warnLabelRect = warnBaseRect.offsetBy(dx: 0, dy: self.header.bounds.height).offsetBy(dx: 0, dy: FlexMediaPickerConfiguration.timeSliderPanelHeight + sOffset)
        self.assetWarningLabel?.frame = warnLabelRect
    }
    
    private func closeView() {
        self.timeSliderPanel?.cleanup()
        self.player?.stop()
        self.player?.url = nil
        self.player = nil
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        self.currentAsset = nil
        self.movieAsset = nil
        self.currentImageSource = nil
        self.finalCleanup()
        self.closeHandler?()
    }
    
    private func updateCurrentPage(toIndex index: Int) {
        self.player?.stop()
        self.imageSlideshow?.isHidden = false
        self.assignFooterPanel(forAssetIndex: index)
    }
    
    @objc private func imageSlideshowTap(_ gesture: UITapGestureRecognizer) {
        self.hideViewElements(hide: !self.header.isHidden)
    }
    
    @objc private func playerSwipeNext(_ gesture: UISwipeGestureRecognizer) {
//        NSLog("\(#function)")
        if let iss = self.imageSlideshow {
            if iss.images.count > 1 {
                DispatchQueue.main.async {
                    self.player?.view.isHidden = true
                    iss.setCurrentPage((iss.currentPage + 1) % iss.images.count, animated: true)
                }
            }
        }
    }

    @objc private func playerSwipePrev(_ gesture: UISwipeGestureRecognizer) {
//        NSLog("\(#function)")
        if let iss = self.imageSlideshow {
            if iss.images.count > 1 {
                DispatchQueue.main.async {
                    self.player?.view.isHidden = true
                    let prevPage = iss.currentPage == 0 ? iss.images.count - 1 : iss.currentPage - 1
                    iss.setCurrentPage(prevPage, animated: true)
                }
            }
        }
    }

    private func isCurrentAssetAVideo() -> Bool {
        if let ca = self.currentAsset {
            return ca.isVideo()
        }
        return false
    }
    
    private func userDidUpdateTimeOffsets() {
        self.doUpdateTimeOffsets()
    }
    
    private func classDidUpdateTimeOffsets() {
        self.doUpdateTimeOffsets()
    }

    private func doUpdateTimeOffsets() {
        if let ca = self.currentAsset {
            ca.minTimeOffset = self.minimumAVOffset
            ca.maxTimeOffset = self.maximumAVOffset
            if ca.isVideo() {
                let maxFrame = self.getMaxFrame()
                let frame = maxFrame * self.currentAVOffset
                ca.currentFrame = frame
                
                let minF = self.minimumAVOffset * maxFrame
                let maxF = self.maximumAVOffset * maxFrame
                ca.minFrame = minF
                ca.maxFrame = maxF
                
                if !FlexMediaPickerConfiguration.allowVideoSelection {
                    self.showWarning(withText: "Videos not accepted, but you can use frames as images.")
                }
                else if FlexMediaPickerConfiguration.maxVideoRecordingTime > 0, let tsp = self.timeSliderPanel, round(tsp.currentDuration()) > FlexMediaPickerConfiguration.maxVideoRecordingTime {
                    self.showWarning(withText: "Maximum allowed duration is \(Helper.stringFromTimeInterval(interval: FlexMediaPickerConfiguration.maxVideoRecordingTime))")
                }
                else {
                    self.assetWarningLabel?.isHidden = true
                }
            }
            else if ca.isAudio() {
                ca.currentTimeOffset = self.currentAVOffset

                if FlexMediaPickerConfiguration.maxAudioRecordingTime > 0, let tsp = self.timeSliderPanel, round(tsp.currentDuration()) > FlexMediaPickerConfiguration.maxAudioRecordingTime {
                    self.showWarning(withText: "Maximum allowed duration is \(Helper.stringFromTimeInterval(interval: FlexMediaPickerConfiguration.maxAudioRecordingTime))")
                }
                else {
                    self.assetWarningLabel?.isHidden = true
                }
            }
        }
    }
    
    func setCurrentPage(_ idx: Int, animated: Bool) {
//        NSLog("\(#function)")
        self.imageSlideshow?.setCurrentPage(idx, animated: animated)
        self.assignFooterPanel(forAssetIndex: idx)
    }
    
    override func hideViewElements(hide: Bool = false) {
        super.hideViewElements(hide: hide)
        self.header.showHide(hide: hide)
        self.footer.showHide(hide: hide)
        self.rightViewMenu?.viewMenu?.showHide(hide: hide)
        if let ass = self.currentAsset, ass.isVideoOrAudio() {
            self.timeSliderPanel?.showHide(hide: hide)
        }
        else {
            self.timeSliderPanel?.showHide(hide: true)
        }
        self.hideViewElementsHandler?(hide)
    }

    private func assignFooterPanel(forAssetIndex index: Int) {
        self.meterTimer?.invalidate()
//        NSLog("\(#function) Asset index is \(index)")
        if let imageAssets = self.imageSlideshow?.images as? [ImageAssetImageSource] {
            let imageAsset = imageAssets[index]
            self.currentAsset = imageAsset.asset
            self.focusedSelectedItem?(imageAsset.asset)
            self.currentImageSource = imageAsset
            self.assetWarningLabel?.isHidden = true

            self.player?.url = nil
            if imageAsset.asset.isVideo() {
                FlexMediaPickerAssetManager.resolveURL(forMediaAsset: imageAsset.asset, resolvedURLHandler: { url in
                    DispatchQueue.main.async {
                        self.videoControlPanel.isHidden = self.header.isHidden
                        self.timeSliderPanel?.showHide(hide: self.header.isHidden)
                        self.videoControlPanel.panelState = .video
                        self.footerText = " "
                        self.assetInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: 0)
                        self.initiateVideoValues(withURL: url)
                        
                        if !FlexMediaPickerConfiguration.allowVideoSelection {
                            self.showWarning(withText: "Videos not accepted, but you can use frames as images.")
                        }
                    }
                })
            }
            else if imageAsset.asset.isAudio() {
                FlexMediaPickerAssetManager.resolveURL(forMediaAsset: imageAsset.asset, resolvedURLHandler: { url in
                    DispatchQueue.main.async {
                        self.videoControlPanel.isHidden = self.header.isHidden
                        self.timeSliderPanel?.showHide(hide: self.header.isHidden)
                        self.videoControlPanel.panelState = .audio
                        self.footerText = " "
                        self.assetInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: 0)
                        self.initiateAudioValues(withURL: url)
                        self.meterTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector:#selector(self.updateAudioMeter(timer:)), userInfo:nil, repeats:true)
                    }
                })
            }
            else {
                self.videoControlPanel.isHidden = true
                self.timeSliderPanel?.showHide(hide: true)
                self.videoControlPanel.panelState = .other
                self.footerText = nil
                self.assetInfoLabel?.label.text = nil
            }

            DispatchQueue.main.async {
                self.cropMI?.selected = !imageAsset.asset.isVideoOrAudio() && FlexMediaPickerConfiguration.maskImage
                self.rightViewMenu?.viewMenu?.setNeedsLayout()
            }
        }
    }
    
    private func initiateVideoValues(withURL url: URL) {
        self.movieAsset = AVURLAsset(url: url, options: nil)
        if let fma = self.currentAsset {
            let totalFrames = self.getMaxFrame()
            self.minimumAVOffset = fma.minFrame / totalFrames
            self.maximumAVOffset = fma.maxFrame == Float64.greatestFiniteMagnitude ? 1 : fma.maxFrame / totalFrames
            self.currentAVOffset = fma.currentFrame / totalFrames
            self.timeSliderPanel?.currentTimeOffset = self.currentAVOffset
            self.timeSliderPanel?.allowedDuration = FlexMediaPickerConfiguration.maxVideoRecordingTime
            self.player?.url = url
        }
    }
    
    private func initiateAudioValues(withURL url: URL) {
        if let fma = self.currentAsset {
            self.audioPlayer = try? AVAudioPlayer(contentsOf: url)
            self.audioPlayer?.delegate = self
            if let ap = self.audioPlayer {
                let dur = ap.duration
                self.maximumAVOffset = fma.maxTimeOffset
                self.minimumAVOffset = fma.minTimeOffset
                self.currentAVOffset = fma.currentTimeOffset
                ap.currentTime = self.currentAVOffset * dur
                self.timeSliderPanel?.currentTimeOffset = self.currentAVOffset
                self.timeSliderPanel?.setMinMaxVideoOffsets(min: self.minimumAVOffset, max: self.maximumAVOffset)
                self.timeSliderPanel?.maxDuration = ap.duration
                let minDur = self.minimumAVOffset * ap.duration
                let maxDur = self.maximumAVOffset * ap.duration
                self.timeSliderPanel?.setMinMaxVideoTime(min: minDur, max: maxDur)
                self.timeSliderPanel?.allowedDuration = FlexMediaPickerConfiguration.maxAudioRecordingTime
                ap.prepareToPlay()
                self.classDidUpdateTimeOffsets()
            }
        }
    }
    
    private func startPositionUpdateNotification() {
        self.posUpdateTimer.start(0.25) { [weak self] in
            if let weakSelf = self {
                if weakSelf.shouldUpdateTimeOffset {
                    weakSelf.shouldUpdateTimeOffset = false
                    DispatchQueue.main.async {
                        weakSelf.updateImageToVideoFrame()
                    }
                }
            }
        }
    }
    
    private func updateVideoTime(toOffset offset: Double, shouldUpdateFrameStepper: Bool = true, shouldUpdateTimeSlider: Bool = true) {
        if let asset = self.movieAsset {
            let durationSeconds = CMTimeGetSeconds(asset.duration)
            let timeOffset = CMTimeMakeWithSeconds(Float64(offset) * durationSeconds, preferredTimescale: 600)
            let movieTracks = asset.tracks(withMediaType: AVMediaType.video)
            if let movieTrack = movieTracks.first {
                let totalFrames: Float64 = durationSeconds * Float64(movieTrack.nominalFrameRate)
                let frame: Float64 = Float64(offset) * totalFrames
                self.currentAsset?.currentFrame = frame
                if shouldUpdateFrameStepper {
                    self.updateFrameStepper()
                }
                if shouldUpdateTimeSlider {
                    self.timeSliderPanel?.currentTimeOffset = self.currentAVOffset
                    self.timeSliderPanel?.setMinMaxVideoOffsets(min: self.minimumAVOffset, max: self.maximumAVOffset)
                }
            }
            DispatchQueue.main.async {
                if let player = self.player {
                    player.seek(to: timeOffset) { success in
                        DispatchQueue.main.async {
                            self.videoControlPanel.isPlaying = player.playbackState == .playing
                        }
                    }
                    self.assetInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: player.currentTime)
                }
            }
        }
        self.shouldUpdateTimeOffset = true
    }
    
    private func updateAudioTime(toOffset offset: Double, shouldUpdateTimeSlider: Bool = true) {
        self.currentAsset?.currentTimeOffset = offset
        if shouldUpdateTimeSlider {
            self.timeSliderPanel?.currentTimeOffset = offset
            self.timeSliderPanel?.setMinMaxVideoOffsets(min: self.minimumAVOffset, max: self.maximumAVOffset)
        }
        DispatchQueue.main.async {
            if let player = self.audioPlayer {
                player.currentTime = offset * player.duration
                self.assetInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: offset * player.duration)
            }
        }
    }
    
    private func getMaxFrame() -> Float64 {
        if let asset = self.movieAsset {
            let movieTracks = asset.tracks(withMediaType: AVMediaType.video)
            if let movieTrack = movieTracks.first {
                let durationSeconds = CMTimeGetSeconds(asset.duration)
                let totalFrames: Float64 = durationSeconds * Float64(movieTrack.nominalFrameRate)
                return totalFrames
            }
        }
        return 1
    }
    
    private func updateFrameStepper() {
        if let asset = self.movieAsset {
            let movieTracks = asset.tracks(withMediaType: AVMediaType.video)
            if let movieTrack = movieTracks.first {
                let durationSeconds = CMTimeGetSeconds(asset.duration)
                let totalFrames = Double(durationSeconds * Float64(movieTrack.nominalFrameRate))
                let minFrame = self.minimumAVOffset * totalFrames
                let maxFrame = self.maximumAVOffset * totalFrames
                if let curFrame = self.currentAsset?.currentFrame {
                    self.videoControlPanel.setFrameValues(min: minFrame, current: floor(Double(curFrame)), max: maxFrame)
                }
            }
        }
    }
    
    private func updateImageToVideoFrame() {
        if let imgSource = self.currentImageSource, let iv = imgSource.imageViewRef {
            imgSource.imageFromVideoURL() { image in
                DispatchQueue.main.async {
                    iv.image = image
                }
            }
        }
    }
    
    // MARK: - Asset Handling
    
    private func applyControlsEnabling() {
        let numApplicableSelected = FlexMediaPickerAssetManager.getAcceptableAssetCount()
        if let ami = self.acceptMI {
            DispatchQueue.main.async {
                ami.enabled = (numApplicableSelected > 0)
                if numApplicableSelected > 0 {
                    if let aicImage = Helper.getAcceptedAssetCountIcon(acceptableAssetCount: numApplicableSelected) {
                        ami.thumbIcon = aicImage
                        self.rightViewMenu?.viewMenu?.thumbSize = aicImage.size
                    }
                }
                self.rightViewMenu?.viewMenu?.setNeedsLayout()
            }
        }
        if !FlexMediaPickerConfiguration.allowMultipleSelection {
            self.videoControlPanel.frameSnapshotAvailable = numApplicableSelected < FlexMediaPickerConfiguration.numberItemsAllowed
        }
    }
    
    // MARK: - AVPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.finishAudioPlay()
    }
    
    private func finishAudioPlay() {
        self.currentAVOffset = self.minimumAVOffset
        self.classDidUpdateTimeOffsets()
        self.updateAudioTime(toOffset: self.minimumAVOffset)
        self.timeSliderPanel?.currentTimeOffset = self.currentAVOffset
        self.videoControlPanel.isPlaying = false
    }
    
    @objc func updateAudioMeter(timer: Timer) {
        if let ap = self.audioPlayer, ap.isPlaying {
            let fraction = Double(ap.currentTime) / Double(ap.duration)
            if !fraction.isNaN {
                if fraction >= self.maximumAVOffset {
                    ap.stop()
                    self.finishAudioPlay()
                }
                else {
                    self.currentAVOffset = min(max(fraction, self.minimumAVOffset), self.maximumAVOffset)
                    self.timeSliderPanel?.currentTimeOffset = self.currentAVOffset
                }

                DispatchQueue.main.async {
                    self.assetInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: ap.currentTime)
                }
            }
        }
    }
    
    // MARK: - PlayerDelegate
    
    func playerReady(_ player: Player) {
        // After player has been initialized, make sure it stays hidden until "play" is tapped
//        NSLog("\(#function)")
        DispatchQueue.main.async {
            if let player = self.player, let fma = self.currentAsset {
                self.timeSliderPanel?.maxDuration = player.maximumDuration
                let minDur = self.minimumAVOffset * player.maximumDuration
                let maxDur = self.maximumAVOffset * player.maximumDuration
                self.timeSliderPanel?.setMinMaxVideoTime(min: minDur, max: maxDur)
                let offset = fma.currentFrame / self.getMaxFrame()
                self.updateVideoTime(toOffset: offset)
                self.classDidUpdateTimeOffsets()
            }
        }
    }
    
    func player(_ player: Player, didFailWithError error: Error?) {
        NSLog("Player did fail with error: \(error!)")
    }

    func playerPlaybackStateDidChange(_ player: Player) {
        self.imageSlideshow?.isHidden = player.playbackState == .playing
    }
    
    func playerBufferingStateDidChange(_ player: Player) {
    }
    
    func playerBufferTimeDidChange(_ bufferTime: Double) {
    }
    
    // MARK: - PlayerPlaybackDelegate
    
    func playerCurrentTimeDidChange(_ player: Player) {
        let current: Double = player.currentTime.seconds
        let maxDur: TimeInterval = player.maximumDuration
        let fraction = Double(current) / Double(maxDur)
        if !fraction.isNaN {
            if fraction >= self.maximumAVOffset {
                self.player?.stop()
                self.videoControlPanel.isPlaying = false
            }

            /// Only update current time when player is playing
            if player.playbackState == .playing {
                self.currentAVOffset = min(max(fraction, self.minimumAVOffset), self.maximumAVOffset)
                self.timeSliderPanel?.currentTimeOffset = self.currentAVOffset
                let maxFrame = self.getMaxFrame()
                let frame = maxFrame * self.currentAVOffset
                self.currentAsset?.currentFrame = frame
                self.updateFrameStepper()
            }
            
            DispatchQueue.main.async {
                self.assetInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: player.currentTime)
            }
        }
    }
    
    func playerPlaybackWillStartFromBeginning(_ player: Player) {
    }
    
    func playerPlaybackDidEnd(_ player: Player) {
        let iTestCurrent = Int(self.currentAVOffset * 600) / 600
        let iTestMax = Int(self.maximumAVOffset * 600) / 600
        if iTestCurrent >= iTestMax {
            self.currentAVOffset = self.minimumAVOffset
            self.classDidUpdateTimeOffsets()
            self.updateVideoTime(toOffset: self.minimumAVOffset)
        }
        self.updateImageToVideoFrame()
    }
    
    func playerPlaybackWillLoop(_ player: Player) {
    }
    
    func playerPlaybackDidLoop(_ player: Player) {
    }
    
    // Helper
    
    private func showWarning(withText text: String) {
        self.assetWarningLabel?.textView.attributedText = Helper.getWarningLabel(withText: text)
        self.assetWarningLabel?.textView.textAlignment = .center
        self.assetWarningLabel?.isHidden = false
    }
    
    private func getTopViewController() -> UIViewController? {
        let appDelegate = UIApplication.shared.delegate
        if let viewController = appDelegate?.window??.rootViewController {
            var topController = viewController
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return appDelegate?.window??.rootViewController
    }
    
}
