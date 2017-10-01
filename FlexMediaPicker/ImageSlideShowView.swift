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
    private var closeViewMenu: CommonIconViewMenu?

    private var startPlayFromStart: Bool = true
    
    var imageSlideshow: ImageSlideshow?
    
    var closeHandler: (()->Void)?
    var hideViewElementsHandler: ((Bool)->Void)?

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
        
        let tgr = UITapGestureRecognizer(target: self, action: #selector(self.imageSlideshowTap(_:)))
        self.addGestureRecognizer(tgr)
        
        self.imageSlideshow?.currentPageChanged = {
            index in
            self.player?.stop()
            self.startPlayFromStart = true
            self.assignFooterPanel(forAssetIndex: index)
        }
        
        // Video Playback
        
        if let tvc = (UIApplication.shared.delegate as? AppDelegate)?.getTopViewController() {
            self.player = Player()
            self.player?.playerDelegate = self
            self.player?.playbackDelegate = self
            self.player?.view.frame = self.bounds
            self.player?.view.isHidden = true
            
            tvc.addChildViewController(self.player!)
            self.addSubview(self.player!.view)
            self.player?.didMove(toParentViewController: tvc)
        }
        
        if let fv = self.footer as? VideoPlaybackControlPanel {
            fv.playPressedHandler = {
                shouldPlay in
                if shouldPlay {
                    if self.startPlayFromStart {
                        self.player?.playFromBeginning()
                        self.startPlayFromStart = false
                    }
                    else {
                        self.player?.playFromCurrentTime()
                    }
                }
                else {
                    self.player?.pause()
                }
            }
            
            fv.setupMenu(in: self)
        }

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageSlideshow?.frame = self.bounds
    }
    
    private func createBackOrCloseLeftMenu() {
        self.closeViewMenu = CommonIconViewMenu(size: CGSize(width: 50, height: 36), hPos: .left, vPos: .header, menuIconSize: 24)
        self.closeViewMenu?.createCloseIconMenuItem()
        self.closeViewMenu?.menuSelectionHandler = {
            type in
            if type == .close {
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
        self.closeViewMenu?.viewMenu?.showHide(forceHide: forceHide)
        self.hideViewElementsHandler?(forceHide)
    }
    
    private func assignFooterPanel(forAssetIndex index: Int) {
        if let imageAssets = self.imageSlideshow?.images as? [ImageAssetImageSource] {
            let imageAsset = imageAssets[index]
            if let ass = imageAsset.asset.asset, ass.mediaType == .video {
                self.videoControlPanel.isHidden = false
                self.footerText = " "
                AssetManager.resolveVideoAsset(ass, resolvedURLHandler: { url in
                    self.player?.url = url
                })
            }
            else if let url = imageAsset.asset.videoURL {
                self.videoControlPanel.isHidden = false
                self.footerText = " "
                self.player?.url = url
            }
            else {
                self.videoControlPanel.isHidden = true
                self.footerText = nil
            }
        }
    }
    
    // MARK: - PlayerDelegate
    
    func playerReady(_ player: Player) {
    }
    
    func playerPlaybackStateDidChange(_ player: Player) {
    }
    
    func playerBufferingStateDidChange(_ player: Player) {
    }
    
    func playerBufferTimeDidChange(_ bufferTime: Double) {
    }
    
    // MARK: - PlayerPlaybackDelegate
    
    func playerCurrentTimeDidChange(_ player: Player) {
    }
    
    func playerPlaybackWillStartFromBeginning(_ player: Player) {
    }
    
    func playerPlaybackDidEnd(_ player: Player) {
    }
    
    func playerPlaybackWillLoop(_ player: Player) {
    }
}
