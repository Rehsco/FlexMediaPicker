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
    var maximumVideoOffset: Double = 1

    var closeHandler: (()->Void)?
    var hideViewElementsHandler: ((Bool)->Void)?
    var didGetPhoto: ((UIImage)->Void)?
    var removeOrTrashSelectedItem: ((FlexMediaPickerAsset)->Void)?

    deinit {
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
        self.addSubview(self.imageSlideshow!)
        
        self.timeSliderPanel = VideoTimeSliderView(frame: CGRect(x: 0, y: FlexMediaPickerConfiguration.headerHeight, width: self.bounds.size.width, height: FlexMediaPickerConfiguration.timeSliderPanelHeight))
        self.timeSliderPanel?.videoTimeOffsetChangeHandler = {
            offset in
            self.updateVideoTime(toOffset: offset)
        }
        self.timeSliderPanel?.videoTimeMinOffsetChangeHandler = {
            offset in
            self.minimumVideoOffset = offset
            self.updateFrameStepper()
        }
        self.timeSliderPanel?.videoTimeMaxOffsetChangeHandler = {
            offset in
            self.maximumVideoOffset = offset
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
                            self.removeFromSuperview()
                        }
                        else {
                            sources.remove(at: cp)
                            iss.setImageInputs(sources)
                            let np = cp % sources.count
                            iss.setCurrentPage(np, animated: true)
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
            self.player?.stop()
            self.imageSlideshow?.isHidden = false
            self.assignFooterPanel(forAssetIndex: index)
        }
        
        // Video Playback
        
        if let tvc = self.getTopViewController() {
            self.player = Player()
            self.player?.playerDelegate = self
            self.player?.playbackDelegate = self
            self.player?.view.frame = self.bounds
            
            tvc.addChildViewController(self.player!)
            self.player?.didMove(toParentViewController: tvc)
            
            let nextGR = UISwipeGestureRecognizer(target: self, action: #selector(self.playerSwipeNext(_:)))
            nextGR.direction = .left
            let prevGR = UISwipeGestureRecognizer(target: self, action: #selector(self.playerSwipePrev(_:)))
            prevGR.direction = .right
            self.player?.view.addGestureRecognizer(nextGR)
            self.player?.view.addGestureRecognizer(prevGR)
        }
        
        if let fv = self.footer as? VideoPlaybackControlPanel {
            fv.frameStepperChangeHandler = {
                newFrame in
                self.currentAsset?.currentFrame = newFrame
                let offset = newFrame / self.getMaxFrame()
                self.updateVideoTime(toOffset: offset, shouldUpdateFrameStepper: false)
            }
            fv.playPressedHandler = {
                shouldPlay in
                if let pp = self.player {
                    if shouldPlay {
                        if pp.view.superview == nil {
                            pp.view.backgroundColor = self.styleColor
                            self.insertSubview(pp.view, at: 1)
                        }
                        self.player?.view.isHidden = false
                        self.imageSlideshow?.isHidden = true
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
                        if FlexMediaPickerConfiguration.storeTakenImagesToPhotos {
                            AssetManager.savePhoto(image, location: nil, completion: {
                                _ in
                                self.didGetPhoto?(image)
                            })
                        }
                        else {
                            self.didGetPhoto?(image)
                        }
                    }
                }
            }
            fv.setupMenu(in: self)
        }
        
        self.startPositionUpdateNotification()
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
                self.player?.stop()
                self.player?.url = nil
                self.currentAsset = nil
                self.movieAsset = nil
                self.currentImageSource = nil
                self.closeHandler?()
            }
        }
        self.addMenu(self.closeViewMenu!)
    }
    
    @objc private func imageSlideshowTap(_ gesture: UITapGestureRecognizer) {
        self.hideViewElements()
    }
    
    @objc private func playerSwipeNext(_ gesture: UISwipeGestureRecognizer) {
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

    func setCurrentPage(_ idx: Int, animated: Bool) {
        self.imageSlideshow?.setCurrentPage(idx, animated: animated)
        self.assignFooterPanel(forAssetIndex: idx)
    }
    
    func hideViewElements(forceHide: Bool = false) {
        self.header.showHide(forceHide: forceHide)
        self.footer.showHide(forceHide: forceHide)
        self.closeViewMenu?.viewMenu?.showHide(forceHide: forceHide)
        self.removeOrTrashViewMenu?.viewMenu?.showHide(forceHide: forceHide)
        if let ass = self.currentAsset, ass.isVideo() {
            self.timeSliderPanel?.showHide(forceHide: forceHide)
        }
        else {
            self.timeSliderPanel?.showHide(forceHide: true)
        }
        self.hideViewElementsHandler?(forceHide)
    }
    
    private func hidePlayerView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: {
            if let p = self.player, !p.view.isHidden {
                self.imageSlideshow?.isHidden = false
                p.view.isHidden = true
                p.view.removeFromSuperview()
            }
        })
    }
    
    private func assignFooterPanel(forAssetIndex index: Int) {
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
                // Hide player view when the image slideshow has loaded the image (again)
                self.hidePlayerView()
            }
            self.player?.url = nil
            if let ass = imageAsset.asset.asset, ass.mediaType == .video {
                self.videoControlPanel.isHidden = self.header.isHidden
                self.timeSliderPanel?.isHidden = self.header.isHidden
                self.videoControlPanel.panelState = .videoTimeSlider
                self.videoControlPanel.showMenu()
                self.footerText = " "
                self.assetInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: 0)
                AssetManager.resolveVideoAsset(ass, resolvedURLHandler: { url in
                    self.initiateVideoValues(withURL: url)
                })
            }
            else if let url = imageAsset.asset.videoURL {
                self.videoControlPanel.isHidden = self.header.isHidden
                self.timeSliderPanel?.isHidden = self.header.isHidden
                self.videoControlPanel.panelState = .videoTimeSlider
                self.videoControlPanel.showMenu()
                self.footerText = " "
                self.assetInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: 0)
                self.initiateVideoValues(withURL: url)
            }
            else {
                self.videoControlPanel.isHidden = true
                self.timeSliderPanel?.isHidden = true
                self.videoControlPanel.panelState = .noVideo
                self.videoControlPanel.showMenu()
                self.footerText = nil
                self.assetInfoLabel?.label.text = nil
                self.player?.view.isHidden = true
            }
        }
    }
    
    private func initiateVideoValues(withURL url: URL) {
        self.movieAsset = AVURLAsset(url: url, options: nil)
        if let fma = self.currentAsset {
            let totalFrames = self.getMaxFrame()
            self.minimumVideoOffset = fma.minFrame / totalFrames
            self.maximumVideoOffset = fma.maxFrame == Float64.greatestFiniteMagnitude ? 1 : fma.maxFrame / totalFrames
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
    
    private func updateVideoTime(toOffset offset: Double, shouldUpdateFrameStepper: Bool = true) {
        if let asset = self.movieAsset {
            let durationSeconds = CMTimeGetSeconds(asset.duration)
            let timeOffset = CMTimeMakeWithSeconds(Float64(offset) * durationSeconds, 600)
            let movieTracks = asset.tracks(withMediaType: AVMediaTypeVideo)
            if let movieTrack = movieTracks.first {
                let totalFrames: Float64 = durationSeconds * Float64(movieTrack.nominalFrameRate)
                let frame: Float64 = Float64(offset) * totalFrames
                let minFrame = self.minimumVideoOffset * totalFrames
                let maxFrame = self.maximumVideoOffset * totalFrames
                self.currentAsset?.currentFrame = frame
                self.currentAsset?.minFrame = minFrame
                self.currentAsset?.maxFrame = maxFrame
                if shouldUpdateFrameStepper {
                    self.updateFrameStepper()
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
        DispatchQueue.main.async {
            if let player = self.player, let fma = self.currentAsset {
                player.view.isHidden = true
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
                self.player?.pause()
                self.videoControlPanel.isPlaying = false
            }
            self.timeSliderPanel?.currentTimeOffset = min(max(fraction, self.minimumVideoOffset), self.maximumVideoOffset)
            
            if player.playbackState == .playing {
                let frame = AssetManager.getVideoFrameForTime(player.currentTime, movieAsset: self.movieAsset)
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
        self.updateVideoTime(toOffset: self.minimumVideoOffset)
        self.updateImageToVideoFrame()
    }
    
    func playerPlaybackWillLoop(_ player: Player) {
    }
}
