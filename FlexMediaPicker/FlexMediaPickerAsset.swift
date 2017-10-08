//
//  FlexMediaPickerAsset.swift
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
import Photos
import AVFoundation

open class FlexMediaPickerAsset {
    var uuid: String
    let thumbnail: UIImage
    var asset: PHAsset?
    
    /// Video
    var videoURL: URL?
    var currentFrame: Float64 = 1
    var minFrame: Float64 = 1
    var maxFrame: Float64 = Float64.greatestFiniteMagnitude
    
    init(thumbnail: UIImage, asset: PHAsset) {
        self.uuid = UUID().uuidString
        self.thumbnail = thumbnail
        self.asset = asset
    }

    init(thumbnail: UIImage) {
        self.uuid = UUID().uuidString
        self.thumbnail = thumbnail
    }

    init(thumbnail: UIImage, videoURL: URL) {
        self.uuid = UUID().uuidString
        self.thumbnail = thumbnail
        self.videoURL = videoURL
    }

    func isAssetBased() -> Bool {
        return self.asset != nil
    }
    
    func isVideo() -> Bool {
        if self.videoURL != nil {
            return true
        }
        if let ass = self.asset, ass.mediaType == .video {
            return true
        }
        return false
    }
}
