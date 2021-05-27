//
//  MainMediaControlPanel.swift
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
import FlexViews
import FlexMenu

class MainMediaControlPanel: MediaControlPanel {
    private var rightMenu: CommonIconViewMenu?
    private var leftMenu: CommonIconViewMenu?

    private var micItem: FlexMenuItem?
    private var locItem: FlexMenuItem?

    override func setupMenu(in flexView: FlexView) {
        super.setupMenu(in: flexView)
        if FlexMediaPickerConfiguration.allowVoiceRecording {
            self.leftMenu = CommonIconViewMenu(size: CGSize(width: 120, height: flexView.footerSize * 0.8), hPos: .left, vPos: .footer, menuIconSize: 36)
            self.micItem = self.leftMenu?.createIconMenuItem(imageName: "micImage", iconSize: 36) {
                self.actionActivationHandler?(.microphone)
            }
            flexView.addMenu(self.leftMenu!)
        }
        if FlexMediaPickerConfiguration.allowLocationSelection {
            self.rightMenu = CommonIconViewMenu(size: CGSize(width: 120, height: flexView.footerSize * 0.8), hPos: .right, vPos: .footer, menuIconSize: 36)
            self.locItem = self.rightMenu?.createIconMenuItem(imageName: "location", iconSize: 36) {
                self.actionActivationHandler?(.location)
            }
            flexView.addMenu(self.rightMenu!)
        }
    }
    
    func setAudioRecordingAvailable(_ available: Bool) {
        self.micItem?.enabled = available
        self.leftMenu?.viewMenu?.setNeedsLayout()
    }

    func setLocationAvailable(_ available: Bool) {
        self.locItem?.enabled = available
        self.rightMenu?.viewMenu?.setNeedsLayout()
    }
}
