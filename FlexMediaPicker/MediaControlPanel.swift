//
//  MediaControlPanel.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 26.08.2017.
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

enum MediaControlAction {
    case camera
    case cameraTake
    case videocamMode
    case videocamTake
    case microphone
}

class MediaControlPanel: FlexFooterView {
    var centerActionButton: FlexFlickButton?
    
    var centerActionButtonHeight: CGFloat = 80
    var centerActionButtonStyle: FlexShapeStyle = FlexShapeStyle(style: .thumb)
    var centerActionButtonStyleColor: UIColor = .black
    var sizingType: ThumbSizingType = .relativeToSlider(min: 10, max: 32)
    
    var actionActivationHandler: ((MediaControlAction)->Void)?
    
    var upperActionItem = FlexFlickActionItem()
    var primaryActionItem = FlexFlickActionItem()
    
    override func initView() {
        super.initView()
        self.centerActionButton = FlexFlickButton(frame: CGRect(origin: .zero, size: CGSize(width: self.centerActionButtonHeight, height: self.centerActionButtonHeight)))
        if let fs = self.centerActionButton {
            fs.style = self.centerActionButtonStyle
            fs.styleColor = self.centerActionButtonStyleColor
            fs.upperActionItem = self.upperActionItem
            fs.primaryActionItem = self.primaryActionItem
            fs.sizingType = self.sizingType
            fs.direction = .vertical
            fs.thumbFactory = {
                index in
                let thumb = MutableSliderThumbItem()
                thumb.color = .clear
                thumb.triggerEventAbove = 0.75
                thumb.triggerEventBelow = 0.25
                return thumb
            }

            self.addSubview(fs)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.centerActionButton?.frame = CGRect(x: (self.bounds.size.width - self.centerActionButtonHeight) * 0.5, y: (self.bounds.size.height - self.centerActionButtonHeight) * 0.5, width: self.centerActionButtonHeight, height: self.centerActionButtonHeight)
    }
}
