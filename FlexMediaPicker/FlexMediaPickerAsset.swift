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
    public var uuid: String
    public let thumbnail: UIImage
    public var asset: PHAsset?
    public let addedTime: Date
    
    /// Video
    public var videoURL: URL?
    public var currentFrame: Float64 = 1
    public var minFrame: Float64 = 1
    public var maxFrame: Float64 = Float64.greatestFiniteMagnitude
    
    /// Image
    public var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1) // Relative to image size

    /// Audio
    public var audioURL: URL?
    public var currentTimeOffset: Double = 0
    
    /// Audio and Video
    public var minTimeOffset: Double = 0
    public var maxTimeOffset: Double = 1
    
    /// Cached info
    public var maxDuration: TimeInterval?

    public init(thumbnail: UIImage, asset: PHAsset) {
        self.uuid = UUID().uuidString
        self.thumbnail = thumbnail
        self.asset = asset
        self.addedTime = Date()
    }

    public init(thumbnail: UIImage) {
        self.uuid = UUID().uuidString
        self.thumbnail = thumbnail
        self.addedTime = Date()
    }

    public init(thumbnail: UIImage, videoURL: URL) {
        self.uuid = UUID().uuidString
        self.thumbnail = thumbnail
        self.videoURL = videoURL
        self.addedTime = Date()
    }
    
    public init(thumbnail: UIImage, audioURL: URL) {
        self.uuid = UUID().uuidString
        self.thumbnail = thumbnail
        self.audioURL = audioURL
        self.addedTime = Date()
    }
    
    func isAssetBased() -> Bool {
        return self.asset != nil
    }
    
    func isVideoOrAudio() -> Bool {
        return self.isVideo() || self.isAudio()
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

    func isAudio() -> Bool {
        if self.audioURL != nil {
            return true
        }
        if let ass = self.asset, ass.mediaType == .audio {
            return true
        }
        return false
    }
}
