//
//  FlexMediaPickerAssetPersistenceImpl.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 04.10.2017.
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
import ImagePersistence
import AVFoundation
import DSWaveformImage
import CoreLocation

open class FlexMediaPickerAssetPersistenceImpl: NSObject, FlexMediaPickerAssetPersistence, AVAudioRecorderDelegate {
    private var assetMap: [String: FlexMediaPickerAsset] = [:]
    private var videoWriter: VideoWriter?
    private var audioRecorder: AVAudioRecorder?
    private var audioRecordingPaused: Bool = false
    private var currentVideoFileURL: URL?
    private var currentAudioFileURL: URL?
    private var exportSession: AVAssetExportSession?
    private var progressUpdateTimer: Timer?

    open var baseVideoDirName = "fmpvideo"
    open var baseAudioDirName = "fmpaudio"

    open var imagePersistence: ImagePersistenceInterface = FlexMediaPickerImagePersistenceImpl(storageID: "FlexMediaPickerImageStorage")!
    
    // MARK: - Asset Management
    
    open func createVideoRecordAsset(thumbnail: UIImage, videoUrl: URL) -> FlexMediaPickerAsset {
        let asset = FlexMediaPickerAsset(thumbnail: thumbnail, videoURL: videoUrl)
        assetMap[asset.uuid] = asset
        return asset
    }
    
    open func createAudioRecordAsset(thumbnail: UIImage, audioUrl: URL) -> FlexMediaPickerAsset {
        let asset = FlexMediaPickerAsset(thumbnail: thumbnail, audioURL: audioUrl)
        assetMap[asset.uuid] = asset
        return asset
    }
    
    open func createImageAsset(thumbnail: UIImage, image: UIImage) -> FlexMediaPickerAsset {
        let asset = FlexMediaPickerAsset(thumbnail: thumbnail)
        assetMap[asset.uuid] = asset
        self.imagePersistence.saveImage(image, imageID: asset.uuid)
        return asset
    }
    
    open func createAssetCollectionAsset(thumbnail: UIImage, asset: PHAsset) -> FlexMediaPickerAsset {
        let asset = FlexMediaPickerAsset(thumbnail: thumbnail, asset: asset)
        assetMap[asset.uuid] = asset
        return asset
    }
    
    open func createLocationAsset(thumbnail: UIImage, location: CLLocation) -> FlexMediaPickerAsset {
        let asset = FlexMediaPickerAsset(thumbnail: thumbnail, location: location)
        assetMap[asset.uuid] = asset
        return asset
    }
    
    open func getAllAssets() -> [FlexMediaPickerAsset] {
        return Array(self.assetMap.values).sorted(by: { $0.addedTime < $1.addedTime })
    }
    
    open func numberOfAssets() -> Int {
        return self.assetMap.count
    }
    
    open func getAsset(forLocalIdentifier id: String) -> FlexMediaPickerAsset? {
        let allAssets = self.getAllAssets()
        for asset in allAssets {
            if let pha = asset.asset, pha.localIdentifier == id {
                return asset
            }
        }
        return nil
    }

    open func getAsset(forID id: String) -> FlexMediaPickerAsset? {
        let allAssets = self.getAllAssets()
        for asset in allAssets {
            if asset.uuid == id {
                return asset
            }
        }
        return nil
    }

    open func imageFromAsset(withID id: String) -> UIImage? {
        if let asset = self.assetMap[id] {
            if asset.isAssetBased() {
                let images = AssetManager.resolveAssets([asset.asset!])
                return images.first
            }
            else {
                return self.imagePersistence.getImage(asset.uuid)
            }
        }
        return nil
    }

    open func deleteImageAsset(withID id: String) {
        if let asset = self.assetMap[id] {
            if asset.isVideo() {
                if let url = asset.videoURL {
                    self.deleteFile(url)
                }
            }
            else {
                self.imagePersistence.deleteImage(id)
            }
            self.assetMap.removeValue(forKey: id)
        }
    }

    open func deleteAllMedia() {
        self.imagePersistence.deleteAllImages()
        self.removeAllAudios()
        self.removeAllVideos()
        self.assetMap.removeAll()
    }
    
    // MARK: - Video
    
    open func isVideoRecorderCreated() -> Bool {
        return self.videoWriter != nil
    }
    
    open func startRecordVideo(height:Int, width:Int, channels:Int, samples:Float64) {
        let fileManager = FileManager()
        self.currentVideoFileURL = self.videoFileUrl()
        if let url = self.currentVideoFileURL {
            if fileManager.fileExists(atPath: url.path) {
                do {
                    try fileManager.removeItem(atPath: url.path)
                } catch _ {
                }
            }
            self.videoWriter = VideoWriter(fileUrl: url, height: height, width: width, channels: channels, samples: samples)
        }
    }
    
    open func writeVideoData(sample: CMSampleBuffer, isVideo: Bool) {
        self.videoWriter?.write(sample: sample, isVideo: isVideo)
    }

    open func stopRecordVideo(finishedHandler: @escaping ((FlexMediaPickerAsset?)->Void)) {
        self.videoWriter?.finish {
            if let vurl = self.currentVideoFileURL {
                if FlexMediaPickerConfiguration.storeRecordedVideosToAssetLibrary {
                    AssetManager.storeVideo(forURL: vurl, completion: { videoAsset in
                        if let asset = videoAsset {
                            AssetManager.resolveVideoAsset(asset, resolvedURLHandler: { url in
                                if let thumbnail = AssetManager.getThumbnailForVideoAsset(url: url) {
                                    finishedHandler(self.createAssetCollectionAsset(thumbnail: thumbnail, asset: asset))
                                }
                            })
                        }
                        self.videoWriter = nil
                    })
                }
                else {
                    if let thumbnail = AssetManager.getThumbnailForVideoAsset(url: vurl) {
                        finishedHandler(self.createVideoRecordAsset(thumbnail: thumbnail, videoUrl: vurl))
                    }
                }
            }
        }
    }
    
    // MARK: - Audio
    
    open func prepareAudioRecording() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default)
            try session.setActive(true)
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
            ]
            self.currentAudioFileURL = self.audioFileUrl()
            audioRecorder = try AVAudioRecorder(url: self.currentAudioFileURL!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
        }
        catch let error {
            NSLog("Voice recorder creation error: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    open func startAudioRecording() -> Bool {
        if self.prepareAudioRecording() {
            self.audioRecorder?.record()
            self.audioRecordingPaused = false
            return true
        }
        return false
    }
    
    open func updateAudioMeter() -> (Float, TimeInterval) {
        if let ar = self.audioRecorder {
            if ar.isRecording {
                ar.updateMeters()
                let avgp = ar.averagePower(forChannel: 0)
                let timeElapsed = ar.currentTime
                return (avgp, timeElapsed)
            }
            else if self.audioRecordingPaused {
                let timeElapsed = ar.currentTime
                return (ar.averagePower(forChannel: 0), timeElapsed)
            }
            else {
                return (ar.averagePower(forChannel: 0), 0.0)
            }
        }
        return (0.0, 0.0)
    }
    
    open func pauseAudioRecording() {
        if let ar = self.audioRecorder {
            if ar.isRecording && !self.audioRecordingPaused {
                ar.pause()
                self.audioRecordingPaused = true
            }
        }
    }

    open func resumeAudioRecording() {
        if self.audioRecordingPaused {
            self.audioRecorder?.record()
            self.audioRecordingPaused = false
        }
    }

    open func stopAudioRecording(_ success: Bool = true, finishedHandler: @escaping ((FlexMediaPickerAsset?)->Void)) {
        if success {
            self.audioRecorder?.stop()
            if let url = self.currentAudioFileURL, let waveform = Waveform(audioAssetURL: url) {
                let configuration = WaveformConfiguration(size: FlexMediaPickerConfiguration.thumbnailSize,
                                                          color: FlexMediaPickerConfiguration.recordingWaveformColor,
                                                          style: .gradient,
                                                          position: .middle,
                                                          scale: UIScreen.main.scale,
                                                          paddingFactor: 4.0)
                if let thumbnail = UIImage(waveform: waveform, configuration: configuration) {
                    finishedHandler(AssetManager.persistence.createAudioRecordAsset(thumbnail: thumbnail, audioUrl: url))
                    return
                }
            }
        }
        finishedHandler(nil)
    }
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // This is executed when starting the recorder with a time limit and currently unused!
        if !flag {
            self.stopAudioRecording(false) {
                _ in
            }
        }
    }
    
    open func cropAudio(_ audioURL: URL, fromTime: CMTime? = nil, duration: CMTime? = nil, progressHandler: ((Float)->Void)? = nil, exportFinishedHandler: @escaping ((URL?)->Void)) {
        self.progressUpdateTimer?.invalidate()
        
        let avAsset = AVURLAsset(url: audioURL, options: nil)
        let startDate = Foundation.Date()
        
        // Create Export session
        self.exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetAppleM4A)
        
        let targetURL = self.audioFileUrl()
        deleteFile(targetURL)
        
        exportSession?.outputURL = targetURL
        exportSession?.outputFileType = AVFileType.m4a
        exportSession?.shouldOptimizeForNetworkUse = true
        let start = fromTime ?? CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
        let range = CMTimeRangeMake(start: start, duration: duration ?? avAsset.duration)
        exportSession?.timeRange = range

        exportSession?.exportAsynchronously(completionHandler: {() -> Void in
            self.progressUpdateTimer?.invalidate()
            switch self.exportSession!.status {
            case .failed:
                NSLog("\(String(describing: self.exportSession!.error))")
            case .cancelled:
                NSLog("Export canceled")
            case .completed:
                // Audio conversion finished
                let endDate = Foundation.Date()
                
                let time = endDate.timeIntervalSince(startDate)
                NSLog("\(time)")
                NSLog("Audio Crop Successful!")
                NSLog(self.exportSession!.outputURL!.absoluteString)
                exportFinishedHandler(self.exportSession?.outputURL)
            default:
                break
            }
        })
        
        DispatchQueue.main.async {
            self.progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { _ in
                if let es = self.exportSession {
                    progressHandler?(es.progress)
                }
            }
        }
    }
    
    /// Crop video

    open func encodeVideo(_ videoURL: URL, fromTime: CMTime? = nil, duration: CMTime? = nil, presetName: String = AVAssetExportPresetPassthrough, progressHandler: ((Float)->Void)? = nil, exportFinishedHandler: @escaping ((URL?)->Void))  {
        self.progressUpdateTimer?.invalidate()
        
        let avAsset = AVURLAsset(url: videoURL, options: nil)
        let startDate = Foundation.Date()
        
        // Create Export session
        self.exportSession = AVAssetExportSession(asset: avAsset, presetName: presetName)

        let targetURL = self.videoFileUrl()
        deleteFile(targetURL)
        
        exportSession?.outputURL = targetURL
        exportSession?.outputFileType = AVFileType.mp4
        exportSession?.shouldOptimizeForNetworkUse = true
        let start = fromTime ?? CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
        let range = CMTimeRangeMake(start: start, duration: duration ?? avAsset.duration)
        exportSession?.timeRange = range
        
        exportSession?.exportAsynchronously(completionHandler: {() -> Void in
            self.progressUpdateTimer?.invalidate()
            switch self.exportSession!.status {
            case .failed:
                NSLog("\(String(describing: self.exportSession!.error))")
            case .cancelled:
                NSLog("Export canceled")
            case .completed:
                //Video conversion finished
                let endDate = Foundation.Date()
                
                let time = endDate.timeIntervalSince(startDate)
                NSLog("\(time)")
                NSLog("Successful!")
                NSLog(self.exportSession!.outputURL!.absoluteString)
                exportFinishedHandler(self.exportSession?.outputURL)
            default:
                break
            }
        })
        
        DispatchQueue.main.async {
            self.progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { _ in
                if let es = self.exportSession {
                    progressHandler?(es.progress)
                }
            }
        }
    }
    
    // MARK: - Helper
    
    open func videoFileUrl() -> URL {
        let videoPath = "/FlexMediaPicker/\(self.baseVideoDirName)"
        self.ensureDirectoryExist(videoPath)
        let url = getDocumentsDirectory().appendingPathComponent("\(videoPath)/\(UUID().uuidString).mp4")
        return url
    }
    
    open func audioFileUrl() -> URL {
        let audioPath = "/FlexMediaPicker/\(self.baseAudioDirName)"
        self.ensureDirectoryExist(audioPath)
        let url = getDocumentsDirectory().appendingPathComponent("\(audioPath)/\(UUID().uuidString).m4a")
        return url
    }
    
    open func removeAllVideos() {
        let videoPath = "FlexMediaPicker/\(self.baseVideoDirName)"
        self.removeAllInDirectory(videoPath)
    }

    open func removeAllAudios() {
        let audioPath = "FlexMediaPicker/\(self.baseAudioDirName)"
        self.removeAllInDirectory(audioPath)
    }

    open func deleteFile(_ filePath:URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else { return }
        
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
            NSLog("File \(filePath.path) deleted")
        }
        catch {
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
    
    open func removeAllInDirectory(_ directoryName: String) {
        let documentDirectory = self.getDocumentsDirectory()
        let directoryURL = documentDirectory.appendingPathComponent(directoryName)
        let path = directoryURL.path
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(atPath: path)
            for file in directoryContents {
                let fullPath = directoryURL.appendingPathComponent(file).path
                do {
                    try FileManager.default.removeItem(atPath: fullPath)
                    NSLog("File \(fullPath) deleted")
                } catch {
                    NSLog("Could not delete file: \(file)")
                }
            }
        }
        catch {
            NSLog("Could not access \(path) for deleting all files")
        }
    }
    
    open func ensureDirectoryExist(_ directoryName: String) {
        let documentDirectory = self.getDocumentsDirectory()
        let directoryURL = documentDirectory.appendingPathComponent(directoryName)
        let path = directoryURL.path
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError {
                NSLog("Cannot create directory at path \(path). Description: \(error.description)")
            }
        }
    }
    
    open func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
