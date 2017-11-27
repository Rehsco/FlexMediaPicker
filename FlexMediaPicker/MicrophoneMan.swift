//
//  MicrophoneMan.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 04.11.2017.
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

open class MicrophoneMan: NSObject {
    private var meterTimer: Timer?
    private(set) var isRecording = false
    private(set) var isPaused = false

    var recordingTimeUpdated: ((TimeInterval, Float)->Void)?
    var voiceRecordedEventHandler: ((FlexMediaPickerAsset)->Void)?
    var voiceRecordingFailedHandler: (()->Void)?

    deinit {
        meterTimer?.invalidate()
        self.stopVoiceRecording()
    }
    
    // MARK: - Session
    
    func setup() {
        self.meterTimer = Timer.scheduledTimer(timeInterval: FlexMediaPickerConfiguration.voiceRecordingUpdateMetricsInterval, target:self, selector:#selector(self.updateAudioMeter(timer:)), userInfo:nil, repeats:true)
    }
    
    func startVoiceRecording() {
        self.recordingTimeUpdated?(0.0, 0.0)
        
        if isRecording {
            self.stopVoiceRecording()
            self.isRecording = false
        }
        else {
            self.isRecording = AssetManager.persistence.startAudioRecording()
        }
    }
    
    @objc func updateAudioMeter(timer: Timer) {
        let (power, time) = AssetManager.persistence.updateAudioMeter()
        self.recordingTimeUpdated?(time, power)
        
        if self.isRecording && FlexMediaPickerConfiguration.maxAudioRecordingTime > 0 && time >= FlexMediaPickerConfiguration.maxAudioRecordingTime {
            self.stopVoiceRecording()
            self.isRecording = false
            
            // TODO: Should inform user of auto recording stop!
        }
    }
    
    func stopVoiceRecording() {
        AssetManager.persistence.stopAudioRecording(true) {
            audioAsset in
            if let aa = audioAsset {
                self.voiceRecordedEventHandler?(aa)
            }
            else {
                self.voiceRecordingFailedHandler?()
            }
        }
    }
    
    func pauseRecording() {
        if self.isRecording {
            NSLog("pause voice recording")
            self.isPaused = true
            AssetManager.persistence.pauseAudioRecording()
        }
    }
    
    func resumeRecording() {
        if self.isRecording && self.isPaused {
            NSLog("resume voice recording")
            self.isPaused = false
            AssetManager.persistence.resumeAudioRecording()
        }
    }

}
