//
//  CameraMediaControlPanel.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 23.09.2017.
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

class CameraMediaControlPanel: FlexFooterView {
    private var flashItem: FlexMenuItem?
    private var backTriggerButton: FlexLabel?
    fileprivate var triggerButton: FlexLabel?
    fileprivate var camVidSwitch: CamVidSwitch?
    
    fileprivate var isVideoModeActive: Bool = false
    
    var camVidSwitchSize: CGSize = CGSize(width: 80, height: 40)
    
    var flashActionHandler: ((Bool)->Void)?
    var cameraSwitchActionHandler: (()->Void)?
    var backToImagesHandler: (()->Void)?
    
    var takePhotoActionHandler: (()->Void)?
    var recVideoActionHandler: (()->Void)?
    
    override func initView() {
        super.initView()
        let vidIcon = UIImage(named: "videoCamImage_36pt", in: Bundle(for: MediaControlPanel.self), compatibleWith: nil)?.tint(FlexMediaPickerConfiguration.iconsColor)
        let camIcon = UIImage(named: "cameraImage_36pt", in: Bundle(for: MediaControlPanel.self), compatibleWith: nil)?.tint(FlexMediaPickerConfiguration.iconsColor)
        let dvidIcon = UIImage(named: "videoCamImage_36pt", in: Bundle(for: MediaControlPanel.self), compatibleWith: nil)?.tint(FlexMediaPickerConfiguration.disabledIconsColor)
        let dcamIcon = UIImage(named: "cameraImage_36pt", in: Bundle(for: MediaControlPanel.self), compatibleWith: nil)?.tint(FlexMediaPickerConfiguration.disabledIconsColor)
        assert(vidIcon != nil && camIcon != nil)
        
        self.backTriggerButton = FlexLabel(frame: CGRect(x: 0, y: 0, width: FlexMediaPickerConfiguration.takeButtonRadius, height: FlexMediaPickerConfiguration.takeButtonRadius))
        self.backTriggerButton?.style = FlexMediaPickerConfiguration.takeButtonStyle
        self.backTriggerButton?.styleColor = FlexMediaPickerConfiguration.takeButtonBorderColor
        self.triggerButton = FlexLabel(frame: CGRect(x: 0, y: 0, width: FlexMediaPickerConfiguration.takeButtonRadius-FlexMediaPickerConfiguration.takeButtonBorderWidth, height: FlexMediaPickerConfiguration.takeButtonRadius-FlexMediaPickerConfiguration.takeButtonBorderWidth))
        self.triggerButton?.style = FlexMediaPickerConfiguration.takeButtonStyle
        self.triggerButton?.styleColor = FlexMediaPickerConfiguration.takeButtonColor
        
        self.camVidSwitch = CamVidSwitch(frame: CGRect(origin: .zero, size: self.camVidSwitchSize), thumbIcon: camIcon!, sepIcon: vidIcon!, disabledThumbIcon: dcamIcon!, disabledSepIcon: dvidIcon!)
        self.camVidSwitch?.onTintColor = .clear
        self.camVidSwitch?.thumbTintColor = FlexMediaPickerConfiguration.camVidSwitchThumbColor
        self.camVidSwitch?.borderColor = FlexMediaPickerConfiguration.camVidSwitchBorderColor
        self.camVidSwitch?.borderWidth = FlexMediaPickerConfiguration.camVidSwitchBorderWidth
        self.camVidSwitch?.style = FlexMediaPickerConfiguration.camVidSwitchStyle
        self.camVidSwitch?.thumbStyle = FlexMediaPickerConfiguration.camVidSwitchStyle
        self.addSubview(self.camVidSwitch!)
        
        self.camVidSwitch?.valueChangedBlock = {
            idx, val in
            self.applyTriggerButtonStyle()
        }
        
        let tgr = UITapGestureRecognizer(target: self, action: #selector(self.onCameraTriggerPressed(_:)))
        self.triggerButton?.addGestureRecognizer(tgr)
        
        self.addSubview(self.backTriggerButton!)
        self.addSubview(self.triggerButton!)
    }
    
    func setupMenu(in flexView: FlexView) {
        let leftMenu = CommonIconViewMenu(size: CGSize(width: 120, height: flexView.footerSize), hPos: .left, vPos: .footer, menuIconSize: 36)
        if !FlexMediaPickerConfiguration.flashButtonAlwaysHidden {
            self.flashItem = leftMenu.createIconMenuItem(imageName: "flashOff", selectedImageName: "flashOn", iconSize: 36) {
                if let fi = self.flashItem {
                    fi.selected = !fi.selected
                    leftMenu.viewMenu?.setNeedsLayout()
                    self.flashActionHandler?(fi.selected)
                }
            }
        }
        if FlexMediaPickerConfiguration.canRotateCamera {
            _ = leftMenu.createIconMenuItem(imageName: "switchCamera", iconSize: 36) {
                self.cameraSwitchActionHandler?()
            }
        }
        flexView.addMenu(leftMenu)
        
        let rightMenu = CommonIconViewMenu(size: CGSize(width: 50, height: flexView.footerSize), hPos: .right, vPos: .footer, menuIconSize: 36)
        _ = rightMenu.createIconMenuItem(imageName: "imageIcon", iconSize: 36) {
            self.backToImagesHandler?()
        }
        flexView.addMenu(rightMenu)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backTriggerButton?.frame = CGRect(x: (self.bounds.size.width - FlexMediaPickerConfiguration.takeButtonRadius) * 0.5, y: (self.bounds.size.height - FlexMediaPickerConfiguration.takeButtonRadius) * 0.5, width: FlexMediaPickerConfiguration.takeButtonRadius, height: FlexMediaPickerConfiguration.takeButtonRadius)
        let triggerDim = FlexMediaPickerConfiguration.takeButtonRadius - FlexMediaPickerConfiguration.takeButtonBorderWidth
        self.triggerButton?.frame = CGRect(x: (self.bounds.size.width - triggerDim) * 0.5, y: (self.bounds.size.height - triggerDim) * 0.5, width: triggerDim, height: triggerDim)
        if self.bounds.size.width < self.bounds.size.height {
            self.camVidSwitch?.frame = CGRect(x: (self.bounds.size.width-self.camVidSwitchSize.height) * 0.5, y: (self.bounds.size.height - self.camVidSwitchSize.width) * 0.2, width: self.camVidSwitchSize.height, height: self.camVidSwitchSize.width)
            self.camVidSwitch?.direction = .vertical
        }
        else {
            self.camVidSwitch?.frame = CGRect(x: (self.bounds.size.width - self.camVidSwitchSize.width) * 0.8, y: (self.bounds.size.height - self.camVidSwitchSize.height) * 0.5, width: self.camVidSwitchSize.width, height: self.camVidSwitchSize.height)
            self.camVidSwitch?.direction = .horizontal
        }
    }
}

extension CameraMediaControlPanel {
    func onCameraTriggerPressed(_ recognizer: UITapGestureRecognizer) {
        guard let cvs = self.camVidSwitch else { return }
        if cvs.on {
            self.isVideoModeActive = !self.isVideoModeActive
            self.recVideoActionHandler?()
        }
        else {
            self.takePhotoActionHandler?()
        }
        self.applyTriggerButtonStyle()
    }
    
    func applyTriggerButtonStyle() {
        guard let cvs = self.camVidSwitch else { return }
        if cvs.on {
            if self.isVideoModeActive {
                self.triggerButton?.styleColor = FlexMediaPickerConfiguration.takeButtonRecordingColor
                self.triggerButton?.style = FlexMediaPickerConfiguration.takeButtonRecordingStyle
            }
            else {
                self.triggerButton?.styleColor = FlexMediaPickerConfiguration.takeButtonNotRecordingColor
                self.triggerButton?.style = FlexMediaPickerConfiguration.takeButtonStyle
            }
        }
        else {
            self.triggerButton?.styleColor = FlexMediaPickerConfiguration.takeButtonColor
            self.triggerButton?.style = FlexMediaPickerConfiguration.takeButtonStyle
        }
    }
}
