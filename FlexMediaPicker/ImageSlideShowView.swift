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

class ImageSlideShowView: FlexView, PlayerDelegate, PlayerPlaybackDelegate {
    private var player: Player?
    private var currentImageSource: ImageAssetImageSource?
    private var currentAsset: FlexMediaPickerAsset?
    private var movieAsset: AVURLAsset?
    private var assetInfoLabel: FlexLabel?
    private var timeSliderPanel: VideoTimeSliderView?
    private let posUpdateTimer = PositionUpdateTimer()
    private var shouldUpdateTimeOffset: Bool = false
    
    private var closeViewMenu: CommonIconViewMenu?
    private var removeOrTrashViewMenu: CommonIconViewMenu?
    private var removeMI: FlexMenuItem?

    var imageSlideshow: ImageSlideshow?
    
    var minimumVideoOffset: Double = 0
    var currentVideoOffset: Double = 0
    var maximumVideoOffset: Double = 1

    var closeHandler: (()->Void)?
    var hideViewElementsHandler: ((Bool)->Void)?
    var didGetPhoto: ((UIImage)->Void)?
    var removeOrTrashSelectedItem: ((FlexMediaPickerAsset)->Void)?

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ScrollViewNotifications.ScrollViewBeginsZoom), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ScrollViewNotifications.ScrollViewEndsZoom), object: nil)

        self.posUpdateTimer.stop()
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
        self.imageSlideshow?.pageControlPosition = .hidden
        
        self.imageSlideshow?.willBeginDragging = {
            self.player?.view.isHidden = true
        }
        
        self.timeSliderPanel = VideoTimeSliderView(frame: CGRect(x: 0, y: FlexMediaPickerConfiguration.headerHeight, width: self.bounds.size.width, height: FlexMediaPickerConfiguration.timeSliderPanelHeight))
        self.timeSliderPanel?.videoTimeOffsetChangeHandler = {
            offset in
            self.currentVideoOffset = offset
            self.userDidUpdateTimeOffsets()
            self.updateVideoTime(toOffset: offset, shouldUpdateFrameStepper: true, shouldUpdateTimeSlider: false)
        }
        self.timeSliderPanel?.videoTimeMinOffsetChangeHandler = {
            offset in
            self.minimumVideoOffset = offset
            self.userDidUpdateTimeOffsets()
            self.updateFrameStepper()
        }
        self.timeSliderPanel?.videoTimeMaxOffsetChangeHandler = {
            offset in
            self.maximumVideoOffset = offset
            self.userDidUpdateTimeOffsets()
            self.updateFrameStepper()
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
        
        self.createBackOrCloseLeftMenu()
        
        self.removeOrTrashViewMenu = CommonIconViewMenu(size: CGSize(width: 50, height: 36), hPos: .right, vPos: .header, menuIconSize: 24)
        self.removeMI = self.removeOrTrashViewMenu?.createIconMenuItem(imageName: "RemoveItem", selectedImageName: "DeleteIcon", iconSize: 24, selectionHandler: {
            if let ci = self.currentAsset {
                self.removeOrTrashSelectedItem?(ci)
                DispatchQueue.main.async {
                    if let iss = self.imageSlideshow {
                        let cp = iss.currentPage
                        var sources = iss.images
                        if sources.count < 2 {
                            self.closeView()
                        }
                        else {
                            sources.remove(at: cp)
                            iss.setImageInputs(sources)
                            let np = cp % sources.count
                            iss.setCurrentPage(np, animated: true)
                            self.updateCurrentPage(toIndex: np)
                        }
                    }
                }
            }
        })
        self.addMenu(self.removeOrTrashViewMenu!)
        
        self.footerSize = FlexMediaPickerConfiguration.footerHeight
        self.footer.styleColor = FlexMediaPickerConfiguration.footerPanelColor
        
        let tgr = UITapGestureRecognizer(target: self, action: #selector(self.imageSlideshowTap(_:)))
        self.addGestureRecognizer(tgr)
        
        self.imageSlideshow?.currentPageChanged = {
            index in
            self.updateCurrentPage(toIndex: index)
        }
        
        // Video Playback
        
        if let tvc = self.getTopViewController() {
            self.player = Player()
            self.player?.playerDelegate = self
            self.player?.playbackDelegate = self
            self.player?.view.frame = self.bounds
            self.player?.view.backgroundColor = FlexMediaPickerConfiguration.styleColor
            
            tvc.addChildViewController(self.player!)
            self.player?.didMove(toParentViewController: tvc)
            
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
                self.currentVideoOffset = offset
                self.userDidUpdateTimeOffsets()
                self.updateVideoTime(toOffset: offset, shouldUpdateFrameStepper: false, shouldUpdateTimeSlider: true)
            }
            fv.playPressedHandler = {
                shouldPlay in
                if let pp = self.player {
                    if shouldPlay {
                        if pp.view.superview == nil {
                            pp.view.backgroundColor = self.styleColor
                        }
                        self.player?.playFromCurrentTime()
                    }
                    else {
                        self.updateImageToVideoFrame()
                        self.player?.pause()
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
    
    func scrollviewBeginsZoom(_ sender: Any) {
        self.player?.view.isHidden = true
    }

    func scrollviewEndsZoom(_ sender: Any) {
        if let ass = self.currentAsset, ass.isVideo() {
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
        self.timeSliderPanel?.frame = CGRect(x: 0, y: FlexMediaPickerConfiguration.headerHeight, width: self.bounds.size.width, height: FlexMediaPickerConfiguration.timeSliderPanelHeight)
    }
    
    private func createBackOrCloseLeftMenu() {
        self.closeViewMenu = CommonIconViewMenu(size: CGSize(width: 50, height: 36), hPos: .left, vPos: .header, menuIconSize: 24)
        self.closeViewMenu?.createCloseIconMenuItem()
        self.closeViewMenu?.menuSelectionHandler = {
            type in
            if type == .close {
                self.closeView()
            }
        }
        self.addMenu(self.closeViewMenu!)
    }
    
    private func closeView() {
        self.player?.stop()
        self.player?.url = nil
        self.currentAsset = nil
        self.movieAsset = nil
        self.currentImageSource = nil
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
        NSLog("\(#function)")
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
        NSLog("\(#function)")
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

    private func userDidUpdateTimeOffsets() {
        self.doUpdateTimeOffsets()
    }
    
    private func classDidUpdateTimeOffsets() {
        self.doUpdateTimeOffsets()
    }

    private func doUpdateTimeOffsets() {
        let maxFrame = self.getMaxFrame()
        let frame = maxFrame * self.currentVideoOffset
        self.currentAsset?.currentFrame = frame
        
        let minF = self.minimumVideoOffset * maxFrame
        let maxF = self.maximumVideoOffset * maxFrame
        self.currentAsset?.minFrame = minF
        self.currentAsset?.maxFrame = maxF
    }
    
    func setCurrentPage(_ idx: Int, animated: Bool) {
        NSLog("\(#function)")
        self.imageSlideshow?.setCurrentPage(idx, animated: animated)
        self.assignFooterPanel(forAssetIndex: idx)
    }
    
    func hideViewElements(hide: Bool = false) {
        self.header.showHide(hide: hide)
        self.footer.showHide(hide: hide)
        self.closeViewMenu?.viewMenu?.showHide(hide: hide)
        self.removeOrTrashViewMenu?.viewMenu?.showHide(hide: hide)
        if let ass = self.currentAsset, ass.isVideo() {
            self.timeSliderPanel?.showHide(hide: hide)
        }
        else {
            self.timeSliderPanel?.showHide(hide: true)
        }
        self.hideViewElementsHandler?(hide)
    }

    // TODO: Need this in fix for scaling/zooming video still image
//    private func hidePlayerView() {
        /*
        DispatchQueue.main.async {
            if let p = self.player, !p.view.isHidden {
                self.imageSlideshow?.isHidden = false
                p.view.isHidden = true
                p.view.removeFromSuperview()
            }
        }
 */
//    }
    
    private func assignFooterPanel(forAssetIndex index: Int) {
        NSLog("\(#function) Asset index is \(index)")
        if let imageAssets = self.imageSlideshow?.images as? [ImageAssetImageSource] {
            let imageAsset = imageAssets[index]
            self.currentAsset = imageAsset.asset
            self.currentImageSource = imageAsset
            
            DispatchQueue.main.async {
                self.removeMI?.selected = !imageAsset.asset.isAssetBased()
                self.removeOrTrashViewMenu?.viewMenu?.setNeedsLayout()
            }
            
            imageAsset.imageFromVideoLoadedHandler = {
                asset in
                // TODO
            }
            self.player?.url = nil
            if imageAsset.asset.isVideo() {
                AssetManager.resolveVideoURL(forMediaAsset: imageAsset.asset, resolvedURLHandler: { url in
                    DispatchQueue.main.async {
                        self.videoControlPanel.isHidden = self.header.isHidden
                        self.timeSliderPanel?.showHide(hide: self.header.isHidden)
                        self.videoControlPanel.panelState = .videoTimeSlider
                        self.footerText = " "
                        self.assetInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: 0)
                        self.initiateVideoValues(withURL: url)
                    }
                })
            }
            else {
                self.videoControlPanel.isHidden = true
                self.timeSliderPanel?.showHide(hide: true)
                self.videoControlPanel.panelState = .noVideo
                self.footerText = nil
                self.assetInfoLabel?.label.text = nil
            }
        }
    }
    
    private func initiateVideoValues(withURL url: URL) {
        self.movieAsset = AVURLAsset(url: url, options: nil)
        if let fma = self.currentAsset {
            let totalFrames = self.getMaxFrame()
            self.minimumVideoOffset = fma.minFrame / totalFrames
            self.maximumVideoOffset = fma.maxFrame == Float64.greatestFiniteMagnitude ? 1 : fma.maxFrame / totalFrames
            self.currentVideoOffset = fma.currentFrame / totalFrames
            self.timeSliderPanel?.currentTimeOffset = self.currentVideoOffset
            self.player?.url = url
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
            let timeOffset = CMTimeMakeWithSeconds(Float64(offset) * durationSeconds, 600)
            let movieTracks = asset.tracks(withMediaType: AVMediaTypeVideo)
            if let movieTrack = movieTracks.first {
                let totalFrames: Float64 = durationSeconds * Float64(movieTrack.nominalFrameRate)
                let frame: Float64 = Float64(offset) * totalFrames
                self.currentAsset?.currentFrame = frame
                if shouldUpdateFrameStepper {
                    self.updateFrameStepper()
                }
                if shouldUpdateTimeSlider {
                    self.timeSliderPanel?.currentTimeOffset = self.currentVideoOffset
                    self.timeSliderPanel?.setMinMaxVideoOffsets(min: self.minimumVideoOffset, max: self.maximumVideoOffset)
                }
            }
            DispatchQueue.main.async {
                if let player = self.player {
                    player.seek(to: timeOffset) {
                        self.videoControlPanel.isPlaying = player.playbackState == .playing
                    }
                    self.assetInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: player.currentTime)
                }
            }
        }
        self.shouldUpdateTimeOffset = true
    }
    
    private func getMaxFrame() -> Float64 {
        if let asset = self.movieAsset {
            let movieTracks = asset.tracks(withMediaType: AVMediaTypeVideo)
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
            let movieTracks = asset.tracks(withMediaType: AVMediaTypeVideo)
            if let movieTrack = movieTracks.first {
                let durationSeconds = CMTimeGetSeconds(asset.duration)
                let totalFrames = Double(durationSeconds * Float64(movieTrack.nominalFrameRate))
                let minFrame = self.minimumVideoOffset * totalFrames
                let maxFrame = self.maximumVideoOffset * totalFrames
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
    
    // MARK: - PlayerDelegate
    
    func playerReady(_ player: Player) {
        // After player has been initialized, make sure it stays hidden until "play" is tapped
        NSLog("\(#function)")
        DispatchQueue.main.async {
            if let player = self.player, let fma = self.currentAsset {
                self.timeSliderPanel?.maxDuration = player.maximumDuration
                let minDur = self.minimumVideoOffset * player.maximumDuration
                let maxDur = self.maximumVideoOffset * player.maximumDuration
                self.timeSliderPanel?.setMinMaxVideoTime(min: minDur, max: maxDur)
                let offset = fma.currentFrame / self.getMaxFrame()
                self.updateVideoTime(toOffset: offset)
            }
        }
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
        let fraction = Double(player.currentTime) / Double(player.maximumDuration)
        if !fraction.isNaN {
            if fraction >= self.maximumVideoOffset {
                self.player?.stop()
                self.videoControlPanel.isPlaying = false
            }

            /// Only update current time when player is playing
            if player.playbackState == .playing {
                self.currentVideoOffset = min(max(fraction, self.minimumVideoOffset), self.maximumVideoOffset)
                self.timeSliderPanel?.currentTimeOffset = self.currentVideoOffset
                let maxFrame = self.getMaxFrame()
                let frame = maxFrame * self.currentVideoOffset
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
        let iTestCurrent = Int(self.currentVideoOffset * 600) / 600
        let iTestMax = Int(self.maximumVideoOffset * 600) / 600
        if iTestCurrent >= iTestMax {
            self.currentVideoOffset = self.minimumVideoOffset
            self.classDidUpdateTimeOffsets()
            self.updateVideoTime(toOffset: self.minimumVideoOffset)
        }
        self.updateImageToVideoFrame()
    }
    
    func playerPlaybackWillLoop(_ player: Player) {
    }
    
    // Helper
    
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
