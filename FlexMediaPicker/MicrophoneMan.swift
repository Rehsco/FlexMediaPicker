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

open class MicrophoneMan: NSObject, AVAudioRecorderDelegate {
    var recordingTimeUpdated: ((TimeInterval, Float)->Void)?
    
    var audioRecorder: AVAudioRecorder?
    var meterTimer:Timer?
    var isAudioRecordingGranted: Bool?
    var isRecording = false
    var isPaused = false
    
    var currentFileURL: URL?
    
    open var audioSampler = AudioSampler()
    
    private var lastPowerSampleTime: TimeInterval = 0
    
    var voiceRecordedEventHandler: ((FlexMediaPickerAsset)->Void)?
    
    deinit {
        meterTimer?.invalidate()
        self.stopVoiceRecording(success: false)
    }
    
    // MARK: - Permission
    
    func checkPermission() {
        switch AVAudioSession.sharedInstance().recordPermission() {
        case .granted:
            isAudioRecordingGranted = true
        case .denied:
            isAudioRecordingGranted = false
        case .undetermined:
            self.requestPermission()
        default:
            // TODO: notify
            break
        }
    }
    
    func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.isAudioRecordingGranted = true
                } else {
                    self.isAudioRecordingGranted = false
                }
            }
        }
    }
    
    // MARK: - Session
    
    /// This will move to persistence
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    /// This will move to persistence
    func getFileUrl() -> URL {
        let filename = "\(UUID().uuidString).m4a"
        let filePath = getDocumentsDirectory().appendingPathComponent(filename)
        return filePath
    }
    
    func setup() {
        self.checkPermission()
        if let granted = isAudioRecordingGranted, granted {
            self.createAudioRecorder()
            self.meterTimer = Timer.scheduledTimer(timeInterval: FlexMediaPickerConfiguration.voiceRecordingUpdateMetricsInterval, target:self, selector:#selector(self.updateAudioMeter(timer:)), userInfo:nil, repeats:true)
        }
        else {
            // TODO: notify
        }
    }
    
    private func createAudioRecorder() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try session.setActive(true)
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
            ]
            self.currentFileURL = getFileUrl()
            audioRecorder = try AVAudioRecorder(url: self.currentFileURL!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
        }
        catch let error {
            // TODO: notify
        }
    }
    
    func startVoiceRecording() {
        self.recordingTimeUpdated?(0.0, 0.0)
        
        if isRecording {
            self.stopVoiceRecording(success: true)
            isRecording = false
        }
        else {
            self.audioSampler.reset()
            self.createAudioRecorder()
            self.audioRecorder?.record()
            isRecording = true
        }
    }
    
    @objc func updateAudioMeter(timer: Timer) {
        if let ar = self.audioRecorder {
            if ar.isRecording {
                ar.updateMeters()
                let avgp = ar.averagePower(forChannel: 0)
                let timeElapsed = ar.currentTime
                self.recordingTimeUpdated?(timeElapsed, avgp)
                
                let normPower = CGFloat(pow (10, avgp / 35))
                let sample = Float(normPower * 100)

                if timeElapsed - self.lastPowerSampleTime > FlexMediaPickerConfiguration.voiceRecordingSamplingInterval {
                    self.lastPowerSampleTime = timeElapsed
                    self.audioSampler.addSample(sample, isSamplingIntervalReached: true)
                }
                else {
                    self.audioSampler.addSample(sample, isSamplingIntervalReached: false)
                }
            }
            else {
                self.recordingTimeUpdated?(0.0, ar.averagePower(forChannel: 0))
            }
        }
    }
    
    func stopVoiceRecording(success: Bool) {
        if success {
            self.audioRecorder?.stop()
            print("recorded successfully.")
            
            // TODO: use persistence layer!
            if let url = self.currentFileURL {
                if let thumbnail = self.audioSampler.generateImageFromSamples() {
                    self.voiceRecordedEventHandler?(AssetManager.persistence.createAudioRecordAsset(thumbnail: thumbnail, audioUrl: url))
                }
            }
        }
        else {
            // TODO: notify
        }
        self.isRecording = false
    }
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopVoiceRecording(success: false)
        }
    }
    
/*
    func pauseRecording() {
        self.lockQueue.sync() {
            if self.isCapturing{
                NSLog("pause voice recording")
                self.isPaused = true
                self.isDiscontinue = true
            }
        }
    }
    
    func resumeRecording() {
        self.lockQueue.sync() {
            if self.isCapturing{
                NSLog("resume voice recording")
                self.isPaused = false
            }
        }
    }
  */

}
