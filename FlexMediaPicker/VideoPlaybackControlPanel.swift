//
//  VideoPlaybackControlPanel.swift
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

enum VideoPlaybackPanelState {
    case videoFrameStep
    case videoTimeSlider
    case noVideo
}

class VideoPlaybackControlPanel: FlexFooterView {
    private var playPauseItem: FlexMenuItem?
    private var cameraItem: FlexMenuItem?
    private var playMenu: CommonIconViewMenu?
    
    var panelState: VideoPlaybackPanelState = .noVideo
    
    var isPlaying: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.playPauseItem?.selected = self.isPlaying
                self.playMenu?.viewMenu?.setNeedsLayout()
            }
        }
    }
    var playPressedHandler: ((Bool)->Void)?
    var snapshotPressedHandler: (()->Void)?

    override func showHide(forceHide: Bool) {
        super.showHide(forceHide: forceHide)
        if self.panelState == .noVideo {
            self.playMenu?.viewMenu?.showHide(forceHide: true)
        }
        else {
            self.playMenu?.viewMenu?.showHide(forceHide: forceHide)
        }
    }
    
    func showMenu() {
        DispatchQueue.main.async {
            if self.panelState == .noVideo {
                self.playMenu?.viewMenu?.isHidden = true
                self.playMenu?.viewMenu?.alpha = 0
            }
            else if !self.isHidden {
                self.playMenu?.viewMenu?.isHidden = false
                self.playMenu?.viewMenu?.alpha = 1
            }
        }
    }
    
    func setupMenu(in flexView: FlexView) {
        self.playMenu = CommonIconViewMenu(size: CGSize(width: 120, height: flexView.footerSize * 0.8), hPos: .center, vPos: .footer, menuIconSize: 36)
        self.cameraItem = self.playMenu?.createIconMenuItem(imageName: "cameraImage" , iconSize: 36) {
            self.snapshotPressedHandler?()
        }
        self.playPauseItem = self.playMenu?.createIconMenuItem(imageName: "playIcon", selectedImageName: "pauseIcon" , iconSize: 36) {
            self.isPlaying = !self.isPlaying
            self.playPressedHandler?(self.isPlaying)
            self.playPauseItem?.selected = self.isPlaying
        }
        flexView.addMenu(self.playMenu!)
    }

}
