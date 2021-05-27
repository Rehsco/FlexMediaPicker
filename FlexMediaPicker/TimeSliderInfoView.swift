//
//  TimeSliderInfoView.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 03.10.2017.
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
import FlexControls

class TimeSliderInfoView: UIView {
    private var minimumTimeLabel: FlexLabel?
    private var durationTimeLabel: FlexLabel?
    private var maximumTimeLabel: FlexLabel?

    var minimumTime: TimeInterval = 0 {
        didSet {
            self.minimumTimeLabel?.label.text = Helper.stringFromTimeInterval(interval: self.minimumTime)
            self.updateDurationLabel()
        }
    }
    var maximumTime: TimeInterval = 1 {
        didSet {
            self.maximumTimeLabel?.label.text = Helper.stringFromTimeInterval(interval: self.maximumTime)
            self.updateDurationLabel()
        }
    }
    
    var allowedDuration: TimeInterval = 0 {
        didSet {
            self.updateDurationLabel()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    private func setupView() {
        self.minimumTimeLabel = self.createDefaultCaptionLabel()
        self.minimumTimeLabel?.labelTextAlignment = .left
        self.addSubview(self.minimumTimeLabel!)
        self.durationTimeLabel = self.createDefaultCaptionLabel()
        self.durationTimeLabel?.labelTextAlignment = .center
        self.addSubview(self.durationTimeLabel!)
        self.maximumTimeLabel = self.createDefaultCaptionLabel()
        self.maximumTimeLabel?.labelTextAlignment = .right
        self.addSubview(self.maximumTimeLabel!)
    }

    private func createDefaultCaptionLabel() -> FlexLabel {
        let label = FlexLabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        label.labelFont = FlexMediaPickerConfiguration.timeSliderCaptionFont
        label.labelTextColor = FlexMediaPickerConfiguration.timeSliderCaptionTextColor
        return label
    }
    
    private func updateDurationLabel() {
        let duration = self.maximumTime - self.minimumTime
        self.durationTimeLabel?.label.text = Helper.stringFromTimeInterval(interval: duration)
        
        if self.allowedDuration > 0 && round(duration) > self.allowedDuration {
            self.durationTimeLabel?.labelTextColor = FlexMediaPickerConfiguration.secondWarningOfRecordingTimeColor
        }
        else {
            self.durationTimeLabel?.labelTextColor = FlexMediaPickerConfiguration.timeSliderCaptionTextColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let minTimeRect = CGRect(x: 0, y: 0, width: 100, height: self.bounds.size.height)
        self.minimumTimeLabel?.frame = minTimeRect
        let maxTimeRect = CGRect(x: self.bounds.width - 100, y: 0, width: 100, height: self.bounds.size.height)
        self.maximumTimeLabel?.frame = maxTimeRect
        let durTimeRect = CGRect(x: (self.bounds.width - 100) * 0.5, y: 0, width: 100, height: self.bounds.size.height)
        self.durationTimeLabel?.frame = durTimeRect
    }
}
