//
//  AudioService.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 06.11.2017.
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
import AVFoundation
import StyledOverlay

let audioService = AudioService()

open class AudioService {
    public var isAudioRecordingGranted: Bool = false

    public func checkPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            self.isAudioRecordingGranted = true
        case .denied, .undetermined:
            self.requestPermission()
        @unknown default:
            self.requestPermission()
        }
    }
    
    func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
            self.isAudioRecordingGranted = allowed
            if !allowed {
                StyledMenuPopoverFactory.showSettingsRequest(title: FlexMediaPickerConfiguration.requestPermissionTitle, message: FlexMediaPickerConfiguration.requestMicrophonePermissionMessage, configuration: FlexMediaPickerStyling.getPopoverViewAppearance())
            }
        }
    }
}
