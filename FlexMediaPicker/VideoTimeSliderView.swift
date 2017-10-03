//
//  VideoTimeSliderView.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 01.10.2017.
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

class VideoTimeSliderView: FlexView {
    private var timeSlider: FlexMutableSlider?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    var currentTimeOffset: Double = 0 {
        didSet {
            self.timeSlider?.updateThumbValue(atIndex: 1, value: self.currentTimeOffset)
        }
    }
    
    var videoTimeOffsetChangeHandler: ((Double)->Void)?
    
    private func setupView() {
        self.styleColor = FlexMediaPickerConfiguration.timeSliderPanelColor

        self.timeSlider = FlexMutableSlider(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.timeSlider?.style = FlexMediaPickerConfiguration.timeSliderStyle
        self.timeSlider?.borderColor = FlexMediaPickerConfiguration.timeSliderBorderColor
        self.timeSlider?.borderWidth = FlexMediaPickerConfiguration.timeSliderBorderWidth
        self.timeSlider?.thumbStyle = FlexMediaPickerConfiguration.timeSliderThumbStyle
        self.timeSlider?.backgroundInsets = FlexMediaPickerConfiguration.timeSliderBarInsets
        self.timeSlider?.valueChangedBlockWhileSliding = {
            value, index in
            if index == 1 {
                // Time offset for video playback change
                self.videoTimeOffsetChangeHandler?(value)
            }
        }
        self.addSubview(self.timeSlider!)
        
        let startOffsetSizeInfo = SliderThumbSizeInfo()
        startOffsetSizeInfo.sizingType = .fixed
        startOffsetSizeInfo.thumbSize = FlexMediaPickerConfiguration.timeSliderBeginEndThumbSize
        
        let startOffsetThumbItem = MutableSliderThumbItem()
        startOffsetThumbItem.behaviour = .freeform
        startOffsetThumbItem.initialValue = 0
        startOffsetThumbItem.color = FlexMediaPickerConfiguration.timeSliderThumbColor
        startOffsetThumbItem.sizeInfo = startOffsetSizeInfo
        
        let startOffsetSepItem = MutableSliderSeparatorItem()
        startOffsetSepItem.color = FlexMediaPickerConfiguration.timeSliderSeparatorColor
        
        self.timeSlider?.addThumb(startOffsetThumbItem, separator: startOffsetSepItem)

        let offsetSizeInfo = SliderThumbSizeInfo()
        offsetSizeInfo.sizingType = .fixed
        offsetSizeInfo.thumbSize = FlexMediaPickerConfiguration.timeSliderThumbSize

        let offsetThumbItem = MutableSliderThumbItem()
        offsetThumbItem.behaviour = .freeform
        offsetThumbItem.initialValue = 0
        offsetThumbItem.color = FlexMediaPickerConfiguration.timeSliderThumbColor
        offsetThumbItem.sizeInfo = offsetSizeInfo
        
        let offsetSepItem = MutableSliderSeparatorItem()
        offsetSepItem.color = FlexMediaPickerConfiguration.timeSliderPanelColor
        
        self.timeSlider?.addThumb(offsetThumbItem, separator: offsetSepItem)

        let stopOffsetSizeInfo = SliderThumbSizeInfo()
        stopOffsetSizeInfo.sizingType = .fixed
        stopOffsetSizeInfo.thumbSize = FlexMediaPickerConfiguration.timeSliderBeginEndThumbSize

        let stopOffsetThumbItem = MutableSliderThumbItem()
        stopOffsetThumbItem.behaviour = .freeform
        stopOffsetThumbItem.initialValue = 1
        stopOffsetThumbItem.color = FlexMediaPickerConfiguration.timeSliderThumbColor
        stopOffsetThumbItem.sizeInfo = stopOffsetSizeInfo
        
        let stopOffsetSepItem = MutableSliderSeparatorItem()
        stopOffsetSepItem.color = FlexMediaPickerConfiguration.timeSliderPanelColor
        
        self.timeSlider?.addThumb(stopOffsetThumbItem, separator: stopOffsetSepItem)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.timeSlider?.frame = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(5, 20, 5, 20))
    }
}
