//
//  VoiceRecorderView.swift
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
import MJRFlexStyleComponents
import SwiftSiriWaveformView

class VoiceRecorderView: FlexView {
    private var voiceRecording: Bool = false
    private var recordingInfoLabel: FlexLabel?
    private var waveformView: SwiftSiriWaveformView?
    
    var vrControlPanel = VoiceRecorderMediaControlPanel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    override var footer: FlexFooterView {
        return self.vrControlPanel
    }

    let micMan = MicrophoneMan()
    
    var didRecordAudio: ((FlexMediaPickerAsset)->Void)?
    var cancelVoiceRecorderViewHandler: (()->Void)?
    var voiceRecordingFailedHandler: (()->Void)? {
        didSet {
            self.micMan.voiceRecordingFailedHandler = self.voiceRecordingFailedHandler
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.backgroundColor = FlexMediaPickerConfiguration.styleColor

        let vr = self.getViewRect()
        self.waveformView = SwiftSiriWaveformView()
        self.waveformView?.frame = vr
        self.waveformView?.backgroundColor = .clear
        self.waveformView?.primaryLineWidth = 3.0
        self.waveformView?.secondaryLineWidth = 1.0
        self.addSubview(self.waveformView!)
        
        micMan.voiceRecordedEventHandler = {
            mpa in
            self.didRecordAudio?(mpa)
        }
        micMan.recordingTimeUpdated = {
            timeElapsed, avgpower in
            DispatchQueue.main.async {
                self.recordingInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: timeElapsed)
                self.recordingInfoLabel?.setNeedsLayout()
                
                // Update waveform
                let normPower = CGFloat(pow (10, avgpower / 35))
                self.waveformView?.amplitude = normPower
                if timeElapsed == 0.0 {
                    self.waveformView?.waveColor = FlexMediaPickerConfiguration.audioWaveformColor
                }
                else {
                    self.waveformView?.waveColor = FlexMediaPickerConfiguration.audioWaveformHighlightColor
                }
            }
        }
        micMan.voiceRecordingFailedHandler = self.voiceRecordingFailedHandler
        micMan.setup()
        
        self.headerSize = FlexMediaPickerConfiguration.headerHeight
        self.header.styleColor = .clear
        
        self.recordingInfoLabel = FlexLabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.recordingInfoLabel?.labelTextColor = FlexMediaPickerConfiguration.headerTextColor
        self.recordingInfoLabel?.labelFont = FlexMediaPickerConfiguration.headerFont
        self.recordingInfoLabel?.labelTextAlignment = .center
        self.recordingInfoLabel?.isHidden = true
        self.addSubview(self.recordingInfoLabel!)
        
        self.footerSize = FlexMediaPickerConfiguration.footerHeight
        self.footerText = " "
        if let ccp = self.footer as? VoiceRecorderMediaControlPanel {
            ccp.setupMenu(in: self)
            
            ccp.recAudioActionHandler = {
                if self.voiceRecording {
                    self.voiceRecording = false
                    self.recordingInfoLabel?.isHidden = true
                    self.stopVoiceRecording()
                }
                else {
                    self.voiceRecording = true
                    self.recordingInfoLabel?.isHidden = false
                    self.startVoiceRecording()
                }
                
            }
            ccp.backToImagesHandler = {
                self.cancelVoiceRecorderViewHandler?()
            }
        }
        self.footer.styleColor = FlexMediaPickerConfiguration.footerPanelColor
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.recordingInfoLabel?.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: FlexMediaPickerConfiguration.headerHeight)
        let vr = self.getViewRect()
        self.waveformView?.frame = vr
    }
    
    // MARK: - Actions

    private func startVoiceRecording() {
        micMan.startVoiceRecording()
    }
    
    private func stopVoiceRecording() {
        micMan.stopVoiceRecording()
    }
}
