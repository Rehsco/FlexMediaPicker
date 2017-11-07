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
import SCLAlertView

let audioService = AudioService()

open class AudioService {
    public var isAudioRecordingGranted: Bool = false

    public func checkPermission() {
        switch AVAudioSession.sharedInstance().recordPermission() {
        case .granted:
            self.isAudioRecordingGranted = true
        case .denied, .undetermined:
            self.requestPermission()
        default:
            break
        }
    }
    
    func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
            DispatchQueue.main.async {
                self.isAudioRecordingGranted = allowed
                if !allowed {
                    let alert = SCLAlertView()
                    alert.addButton("Open Settings") {
                        if let url = URL(string:UIApplicationOpenSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    let _ = alert.showTitle("Microphone Access Disabled", subTitle: "In order to record audio, please open this app's settings and enable microphone access.", style: SCLAlertViewStyle.error)
                }
            }
        }
    }
}
