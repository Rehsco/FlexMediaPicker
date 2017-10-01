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

    private var closeViewMenu: CommonIconViewMenu?

    private var startPlayFromStart: Bool = true
    
    var imageSlideshow: ImageSlideshow?
    
    var closeHandler: (()->Void)?
    var hideViewElementsHandler: ((Bool)->Void)?
    var didGetPhoto: ((UIImage)->Void)?

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
        
        self.headerText = " "
        self.headerSize = FlexMediaPickerConfiguration.headerHeight
        self.header.styleColor = FlexMediaPickerConfiguration.headerColor
        self.createBackOrCloseLeftMenu()
        
        self.footerSize = FlexMediaPickerConfiguration.footerHeight
        self.footer.styleColor = FlexMediaPickerConfiguration.footerPanelColor
        
        let tgr = UITapGestureRecognizer(target: self, action: #selector(self.imageSlideshowTap(_:)))
        self.addGestureRecognizer(tgr)
        
        self.imageSlideshow?.currentPageChanged = {
            index in
            self.player?.stop()
            self.startPlayFromStart = true
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
        }
        
        if let fv = self.footer as? VideoPlaybackControlPanel {
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
                        if self.startPlayFromStart {
                            self.player?.playFromBeginning()
                            self.startPlayFromStart = false
                        }
                        else {
                            self.player?.playFromCurrentTime()
                        }
                    }
                    else {
                        self.updateImageToVideoFrame()
                        self.player?.pause()
                    }
                }
            }
            fv.snapshotPressedHandler = {
                self.currentImageSource?.getVideoURL(completionHandler: { videoUrl in
                    if let url = videoUrl {
                        if let image = self.currentImageSource?.imageFromVideo(url: url) {
                            AssetManager.savePhoto(image, location: nil, completion: {
                                _ in
                                self.didGetPhoto?(image)
                            })
                        }
                    }
                })
            }
            fv.setupMenu(in: self)
        }
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageSlideshow?.frame = self.bounds
        self.player?.view.frame = self.bounds
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
    
    func setCurrentPage(_ idx: Int, animated: Bool) {
        self.imageSlideshow?.setCurrentPage(idx, animated: animated)
        self.assignFooterPanel(forAssetIndex: idx)
    }
    
    func hideViewElements(forceHide: Bool = false) {
        self.header.showHide(forceHide: forceHide)
        self.footer.showHide(forceHide: forceHide)
        self.closeViewMenu?.viewMenu?.showHide(forceHide: forceHide)
        self.hideViewElementsHandler?(forceHide)
    }
    
    private func assignFooterPanel(forAssetIndex index: Int) {
        if let imageAssets = self.imageSlideshow?.images as? [ImageAssetImageSource] {
            let imageAsset = imageAssets[index]
            self.currentAsset = imageAsset.asset
            self.currentImageSource = imageAsset
            imageAsset.imageFromVideoLoadedHandler = {
                asset in
                // Hide player view when the image slideshow has loaded the image (again)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: {
                    if let p = self.player, !p.view.isHidden {
                        self.imageSlideshow?.isHidden = false
                        p.view.isHidden = true
                        p.view.removeFromSuperview()
                    }
                })
            }
            self.player?.url = nil
            if let ass = imageAsset.asset.asset, ass.mediaType == .video {
                self.videoControlPanel.isHidden = self.header.isHidden
                self.videoControlPanel.panelState = .videoTimeSlider
                self.videoControlPanel.showMenu()
                self.footerText = " "
                AssetManager.resolveVideoAsset(ass, resolvedURLHandler: { url in
                    self.player?.url = url
                    self.movieAsset = AVURLAsset(url: url, options: nil)
                })
            }
            else if let url = imageAsset.asset.videoURL {
                self.videoControlPanel.isHidden = self.header.isHidden
                self.videoControlPanel.panelState = .videoTimeSlider
                self.videoControlPanel.showMenu()
                self.footerText = " "
                self.player?.url = url
                self.movieAsset = AVURLAsset(url: url, options: nil)
            }
            else {
                self.videoControlPanel.isHidden = true
                self.videoControlPanel.panelState = .noVideo
                self.videoControlPanel.showMenu()
                self.footerText = nil
                self.player?.view.isHidden = true
            }
        }
    }
    
    private func getVideoFrameForTime(time: TimeInterval) -> Float64 {
        if let asset = self.movieAsset {
            let movieTracks = asset.tracks(withMediaType: AVMediaTypeVideo)
            if let movieTrack = movieTracks.first {
                let durationSeconds = CMTimeGetSeconds(asset.duration)
                let totalFrames: Float64 = durationSeconds * Float64(movieTrack.nominalFrameRate)
                let frame: Float64 = Float64(time) / Float64(durationSeconds) * totalFrames
                return frame
            }
        }
        return 0
    }
    
    private func updateImageToVideoFrame() {
        if let iss = self.imageSlideshow {
            // Hack to reload
            iss.setImageInputs(iss.images)
        }
    }
    
    // MARK: - PlayerDelegate
    
    func playerReady(_ player: Player) {
        // After player has been initialized, make sure it stays hidden until "play" is tapped
        DispatchQueue.main.async {
            self.player?.view.isHidden = true
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
        let frame = self.getVideoFrameForTime(time: player.currentTime)
        self.currentAsset?.currentFrame = frame
    }
    
    func playerPlaybackWillStartFromBeginning(_ player: Player) {
    }
    
    func playerPlaybackDidEnd(_ player: Player) {
        self.currentAsset?.currentFrame = 1
        self.videoControlPanel.isPlaying = false
        self.updateImageToVideoFrame()
    }
    
    func playerPlaybackWillLoop(_ player: Player) {
    }
}
