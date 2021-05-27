//
//  CamVidSwitch.swift
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
import FlexSlider

class CamVidSwitch: FlexSwitch {
    private var thumbIcon: UIImage?
    private var sepIcon: UIImage?
    private var disabledThumbIcon: UIImage?
    private var disabledSepIcon: UIImage?
    
    init(frame: CGRect, thumbIcon: UIImage, sepIcon: UIImage, disabledThumbIcon: UIImage, disabledSepIcon: UIImage) {
        self.sepIcon = sepIcon
        self.thumbIcon = thumbIcon
        self.disabledSepIcon = disabledSepIcon
        self.disabledThumbIcon = disabledThumbIcon
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func iconOfThumb(_ index: Int) -> UIImage? {
        if self.on {
            return sepIcon
        }
        else {
            return thumbIcon
        }
    }
    
    override func iconOfSeparator(_ index: Int) -> UIImage? {
        return index == 0 ? (self.on ? disabledThumbIcon : nil) : (self.on ? nil : disabledSepIcon)
    }
}
