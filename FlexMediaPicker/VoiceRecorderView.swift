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
import FlexViews
import FlexControls
import StyledOverlay

class VoiceRecorderView: FlexView {
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
            self.vrControlPanel.isRecording = false
            self.vrControlPanel.applyTriggerButtonStyle()
            self.vrControlPanel.showHide(hide: false)
        }
        micMan.recordingTimeUpdated = {
            timeElapsed, avgpower in
            DispatchQueue.main.async {
                if self.micMan.isPaused {
                    self.recordingInfoLabel?.label.text = "Paused at \(Helper.stringFromTimeInterval(interval: timeElapsed))"
                    self.recordingInfoLabel?.setNeedsLayout()
                }
                else {
                    self.recordingInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: timeElapsed)
                    self.recordingInfoLabel?.setNeedsLayout()
                }

                if FlexMediaPickerConfiguration.maxAudioRecordingTime > 0 {
                    if FlexMediaPickerConfiguration.maxAudioRecordingTime - timeElapsed <= FlexMediaPickerConfiguration.secondWarningForRecordingLimitAtTimeLeft {
                        self.recordingInfoLabel?.labelTextColor = FlexMediaPickerConfiguration.secondWarningOfRecordingTimeColor
                    }
                    else if FlexMediaPickerConfiguration.maxAudioRecordingTime - timeElapsed <= FlexMediaPickerConfiguration.firstWarningForRecordingLimitAtTimeLeft {
                        self.recordingInfoLabel?.labelTextColor = FlexMediaPickerConfiguration.firstWarningOfRecordingTimeColor
                    }
                    else {
                        self.recordingInfoLabel?.labelTextColor = FlexMediaPickerConfiguration.headerTextColor
                    }
                }

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
                if self.micMan.isRecording {
                    self.recordingInfoLabel?.isHidden = true
                    self.stopVoiceRecording()
                }
                else {
                    self.recordingInfoLabel?.isHidden = false
                    self.startVoiceRecording()
                }
                
            }
            ccp.backToImagesHandler = {
                self.confirmedClose()
            }
            ccp.pausePressedHandler = {
                isPaused in
                if isPaused {
                    self.micMan.pauseRecording()
                }
                else {
                    self.micMan.resumeRecording()
                }
            }
        }
        self.footer.styleColor = FlexMediaPickerConfiguration.footerPanelColor
    }
    
    public func confirmedClose(confirmationHandler: ((Bool)->Void)? = nil) {
        if self.micMan.isRecording {
            StyledMenuPopoverFactory.confirmation(title: FlexMediaPickerConfiguration.stopRecordingOnCloseTitle, subTitle: FlexMediaPickerConfiguration.stopRecordingOnCloseMessage, buttonText: FlexMediaPickerConfiguration.stopRecordingOnCloseButtonText, iconName: FlexMediaPickerConfiguration.queryIconName, configuration: FlexMediaPickerStyling.getPopoverViewAppearance(), confirmationResult: { confirmed in
                if confirmed {
                    self.closeAndClean()
                }
                confirmationHandler?(confirmed)
            })
        }
        else {
            self.closeAndClean()
            confirmationHandler?(true)
        }
    }

    private func closeAndClean() {
        self.closeView()
        self.cancelVoiceRecorderViewHandler?()
    }
    
    public func closeView() {
        if self.micMan.isRecording {
            self.stopVoiceRecording()
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var yoff:CGFloat = 0
        if #available(iOS 11, *) {
            yoff = self.safeAreaInsets.top
        }
        self.recordingInfoLabel?.frame = CGRect(x: 0, y: yoff, width: self.bounds.size.width, height: FlexMediaPickerConfiguration.headerHeight)
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
