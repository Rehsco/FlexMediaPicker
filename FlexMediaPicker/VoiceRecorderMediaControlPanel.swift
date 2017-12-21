//
//  VoiceRecorderMediaControlPanel.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 04.11.2017.
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

class VoiceRecorderMediaControlPanel: FlexFooterView {
    private var rightMenu: CommonIconViewMenu?
    private var leftMenu: CommonIconViewMenu?
    fileprivate var backTriggerButton: FlexLabel?
    private var ringTriggerButton: FlexLabel?
    fileprivate var triggerButton: FlexLabel?
    private var recordingPauseItem: FlexMenuItem?

    var backToImagesHandler: (()->Void)?
    var recAudioActionHandler: (()->Void)?
    
    var isRecording = false
    
    var isPaused: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.recordingPauseItem?.selected = self.isPaused
                self.leftMenu?.viewMenu?.setNeedsLayout()
            }
        }
    }
    var pausePressedHandler: ((Bool)->Void)?
    
    override func initView() {
        super.initView()
        
        self.backTriggerButton = FlexLabel(frame: CGRect(x: 0, y: 0, width: FlexMediaPickerConfiguration.takeButtonRadius, height: FlexMediaPickerConfiguration.takeButtonRadius))
        self.backTriggerButton?.style = FlexMediaPickerConfiguration.takeButtonStyle
        self.backTriggerButton?.styleColor = FlexMediaPickerConfiguration.takeButtonBorderColor
        self.ringTriggerButton = FlexLabel(frame: CGRect(x: 0, y: 0, width: FlexMediaPickerConfiguration.takeButtonRadius - FlexMediaPickerConfiguration.takeButtonRingWidth, height: FlexMediaPickerConfiguration.takeButtonRadius - FlexMediaPickerConfiguration.takeButtonRingWidth))
        self.ringTriggerButton?.style = FlexMediaPickerConfiguration.takeButtonStyle
        self.ringTriggerButton?.styleColor = FlexMediaPickerConfiguration.takeButtonRingColor
        self.triggerButton = FlexLabel(frame: CGRect(x: 0, y: 0,
                                                     width: FlexMediaPickerConfiguration.takeButtonRadius-(FlexMediaPickerConfiguration.takeButtonBorderWidth + FlexMediaPickerConfiguration.takeButtonRingWidth),
                                                     height: FlexMediaPickerConfiguration.takeButtonRadius-(FlexMediaPickerConfiguration.takeButtonBorderWidth + FlexMediaPickerConfiguration.takeButtonRingWidth)))
        self.triggerButton?.style = FlexMediaPickerConfiguration.takeButtonStyle
        self.triggerButton?.styleColor = FlexMediaPickerConfiguration.takeButtonColor

        let tgr = UITapGestureRecognizer(target: self, action: #selector(self.onRecordingPressed(_:)))
        self.triggerButton?.addGestureRecognizer(tgr)
        
        self.addSubview(self.backTriggerButton!)
        self.addSubview(self.ringTriggerButton!)
        self.addSubview(self.triggerButton!)
    }
    
    func setupMenu(in flexView: FlexView) {
        self.leftMenu = CommonIconViewMenu(size: CGSize(width: 120, height: flexView.footerSize), hPos: .left, vPos: .footer, menuIconSize: 36)
        self.recordingPauseItem = self.leftMenu?.createIconMenuItem(imageName: "pauseIcon", selectedImageName: "pausedIcon", selectedIconTintColor: FlexMediaPickerConfiguration.pausedRecordingIconTintColor, iconSize: 36) {
            self.isPaused = !self.isPaused
            self.pausePressedHandler?(self.isPaused)
        }
        self.leftMenu?.viewMenu?.isHidden = true
        flexView.addMenu(self.leftMenu!)
        
        self.rightMenu = CommonIconViewMenu(size: CGSize(width: 50, height: flexView.footerSize), hPos: .right, vPos: .footer, menuIconSize: 24)
        _ = rightMenu?.createIconMenuItem(imageName: "CloseView", iconSize: 24) {
            self.backToImagesHandler?()
        }
        flexView.addMenu(self.rightMenu!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backTriggerButton?.frame = CGRect(x: (self.bounds.size.width - FlexMediaPickerConfiguration.takeButtonRadius) * 0.5, y: (self.bounds.size.height - FlexMediaPickerConfiguration.takeButtonRadius) * 0.5, width: FlexMediaPickerConfiguration.takeButtonRadius, height: FlexMediaPickerConfiguration.takeButtonRadius)
        let ringSize = (FlexMediaPickerConfiguration.takeButtonRadius - FlexMediaPickerConfiguration.takeButtonBorderWidth) + FlexMediaPickerConfiguration.takeButtonRingWidth
        self.ringTriggerButton?.frame = CGRect(x: (self.bounds.size.width - ringSize) * 0.5,
                                               y: (self.bounds.size.height - ringSize) * 0.5,
                                               width: ringSize, height: ringSize)
        let triggerDim = FlexMediaPickerConfiguration.takeButtonRadius - (FlexMediaPickerConfiguration.takeButtonBorderWidth + FlexMediaPickerConfiguration.takeButtonRingWidth)
        self.triggerButton?.frame = CGRect(x: (self.bounds.size.width - triggerDim) * 0.5, y: (self.bounds.size.height - triggerDim) * 0.5, width: triggerDim, height: triggerDim)
    }
    
    override func showHide(hide: Bool, completionHandler: (()->Void)? = nil) {
        super.showHide(hide: hide, completionHandler: completionHandler)
        if self.isRecording {
            self.rightMenu?.viewMenu?.showHide(hide: true)
            self.leftMenu?.viewMenu?.showHide(hide: false)
        }
        else {
            self.rightMenu?.viewMenu?.showHide(hide: hide)
            self.leftMenu?.viewMenu?.showHide(hide: true)
        }
    }
}

extension VoiceRecorderMediaControlPanel {
    @objc func onRecordingPressed(_ recognizer: UITapGestureRecognizer) {
        self.isRecording = !self.isRecording
        self.recAudioActionHandler?()
        self.applyTriggerButtonStyle()
        self.showHide(hide: false)
    }
    
    func applyTriggerButtonStyle() {
        self.backTriggerButton?.styleColor = FlexMediaPickerConfiguration.takeButtonBorderColor
        if self.isRecording {
            self.triggerButton?.styleColor = FlexMediaPickerConfiguration.takeButtonRecordingColor
        }
        else {
            self.triggerButton?.styleColor = FlexMediaPickerConfiguration.takeButtonNotRecordingColor
        }
    }
}
