//
//  VideoWriter.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 11.09.2017.
//  Copyright © 2017 Martin Jacob Rehder. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary

class VideoWriter {
    var fileWriter: AVAssetWriter!
    var videoInput: AVAssetWriterInput!
    var audioInput: AVAssetWriterInput!
    
    init(fileUrl:URL!, height:Int, width:Int, channels:Int, samples:Float64){
        fileWriter = try? AVAssetWriter(outputURL: fileUrl, fileType: AVFileTypeQuickTimeMovie)
        
        let videoOutputSettings: Dictionary<String, AnyObject> = [
            AVVideoCodecKey : AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey : width as AnyObject,
            AVVideoHeightKey : height as AnyObject
        ];
        videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = true
        fileWriter.add(videoInput)
        
        let audioOutputSettings: Dictionary<String, AnyObject> = [
            AVFormatIDKey : Int(kAudioFormatMPEG4AAC) as AnyObject,
            AVNumberOfChannelsKey : channels as AnyObject,
            AVSampleRateKey : samples as AnyObject,
            AVEncoderBitRateKey : 128000 as AnyObject
        ]
        audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioOutputSettings)
        audioInput.expectsMediaDataInRealTime = true
        fileWriter.add(audioInput)
    }
    
    func write(sample: CMSampleBuffer, isVideo: Bool){
        if CMSampleBufferDataIsReady(sample) {
            if fileWriter.status == AVAssetWriterStatus.unknown {
                NSLog("Start writing, isVideo = \(isVideo), status = \(fileWriter.status.rawValue)")
                let startTime = CMSampleBufferGetPresentationTimeStamp(sample)
                fileWriter.startWriting()
                fileWriter.startSession(atSourceTime: startTime)
            }
            if fileWriter.status == AVAssetWriterStatus.failed {
                NSLog("Error occured, isVideo = \(isVideo), status = \(fileWriter.status.rawValue), \(fileWriter.error!.localizedDescription)")
                return
            }
            if isVideo {
                if videoInput.isReadyForMoreMediaData {
                    videoInput.append(sample)
                }
            }else{
                if audioInput.isReadyForMoreMediaData {
                    audioInput.append(sample)
                }
            }
        }
    }
    
    func finish(callback: @escaping () -> Void){
        fileWriter.finishWriting(completionHandler: callback)
    }
}
