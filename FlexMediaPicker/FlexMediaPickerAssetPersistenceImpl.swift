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

open class FlexMediaPickerAssetPersistenceImpl: FlexMediaPickerAssetPersistence {    
    private var assetMap: [String: FlexMediaPickerAsset] = [:]
    private var videoWriter: VideoWriter?
    private var fileIndex = 0
    private var exportSession: AVAssetExportSession?
    
    open var imagePersistence: ImagePersistenceInterface = FlexMediaPickerImagePersistenceImpl()!
    
    open func createVideoRecordAsset(thumbnail: UIImage, videoUrl: URL) -> FlexMediaPickerAsset {
        let asset = FlexMediaPickerAsset(thumbnail: thumbnail, videoURL: videoUrl)
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
    
    open func imageFromAsset(withID id: String) -> UIImage? {
        if let asset = self.assetMap[id] {
            if asset.isAssetBased() {
                let images = AssetManager.resolveAssets([asset.asset!])
                NSLog("\(#function): Asset based image for \(asset.uuid)")
                return images.first
            }
            else {
                NSLog("\(#function): persisted image for \(asset.uuid)")
                return self.imagePersistence.getImage(asset.uuid)
            }
        }
        return nil
    }

    open func deleteImageAsset(withID id: String) {
        if let asset = self.assetMap[id] {
            if asset.isVideo(), let url = asset.videoURL {
                NSLog("Deleting video. Deleting file \(url.absoluteString)")
                self.deleteFile(url)
            }
            else {
                NSLog("Deleting image")
                self.imagePersistence.deleteImage(id)
            }
            self.assetMap.removeValue(forKey: id)
        }
    }

    open func isVideoRecorderCreated() -> Bool {
        return self.videoWriter != nil
    }
    
    open func startRecordVideo(height:Int, width:Int, channels:Int, samples:Float64) {
        let fileManager = FileManager()
        if fileManager.fileExists(atPath: self.filePath()) {
            do {
                try fileManager.removeItem(atPath: self.filePath())
            } catch _ {
            }
        }
        NSLog("setup video writer with \(width), \(height)")
        self.videoWriter = VideoWriter(fileUrl: self.filePathUrl(), height: height, width: width, channels: channels, samples: samples)
    }
    
    open func writeVideoData(sample: CMSampleBuffer, isVideo: Bool) {
        self.videoWriter?.write(sample: sample, isVideo: isVideo)
    }

    open func stopRecordVideo(finishedHandler: @escaping ((FlexMediaPickerAsset?)->Void)) {
        self.videoWriter?.finish {
            if FlexMediaPickerConfiguration.storeRecordedVideosToAssetLibrary {
                AssetManager.storeVideo(forURL: self.filePathUrl(), completion: { videoAsset in
                    if let asset = videoAsset {
                        AssetManager.resolveVideoAsset(asset, resolvedURLHandler: { url in
                            if let thumbnail = AssetManager.getThumbnailForVideoAsset(url: url) {
                                finishedHandler(self.createAssetCollectionAsset(thumbnail: thumbnail, asset: asset))
                            }
                        })
                    }
                    self.fileIndex += 1
                    self.videoWriter = nil
                })
            }
            else {
                if let thumbnail = AssetManager.getThumbnailForVideoAsset(url: self.filePathUrl()) {
                    finishedHandler(self.createVideoRecordAsset(thumbnail: thumbnail, videoUrl: self.filePathUrl()))
                }
            }
        }
    }
    
    // MARK: - Helper
    
    func filePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String = "\(documentsDirectory)/video\(self.fileIndex).mp4"
        return filePath
    }
    
    func filePathUrl() -> URL! {
        return URL(fileURLWithPath: self.filePath())
    }

    /// Crop video

    // TODO: Need to change this to work with FlexMediaAsset model
    // TODO: Need to use a progress indication handler as well
    func encodeVideo(_ videoURL: URL, fromTime: CMTime? = nil, duration: CMTime? = nil, presetName: String = AVAssetExportPresetPassthrough, exportFinishedHandler: @escaping ((URL?)->Void))  {
        
        let avAsset = AVURLAsset(url: videoURL, options: nil)
        let startDate = Foundation.Date()
        
        //Create Export session
        /// Seems that you can set the preset name to for example: AVAssetExportPreset640x480 for 480p export
        let exportSession = AVAssetExportSession(asset: avAsset, presetName: presetName)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        // TODO: This needs to be based on the UUID as filename
        let filePath = documentsDirectory.appendingPathComponent("rendered-Video.mp4")
        deleteFile(filePath)
        
        exportSession?.outputURL = filePath
        exportSession?.outputFileType = AVFileTypeMPEG4
        exportSession?.shouldOptimizeForNetworkUse = true
        let start = fromTime ?? CMTimeMakeWithSeconds(0.0, 0)
        let range = CMTimeRangeMake(start, duration ?? avAsset.duration)
        exportSession?.timeRange = range
        
        exportSession!.exportAsynchronously(completionHandler: {() -> Void in
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
    }
    
    func deleteFile(_ filePath:URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return
        }
        
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        }
        catch {
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
    
    /// Resource provider instead of URL based playback code
    /*
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        if let data = self.videoData {
            DispatchQueue.main.async { () -> Void in
                if let infoRequest = loadingRequest.contentInformationRequest {
                    infoRequest.contentType = "public.mpeg-4" // UTI
                    infoRequest.contentLength = Int64(data.count)
                    infoRequest.isByteRangeAccessSupported = true
                }
                if let request = loadingRequest.dataRequest {
                    let range = Range(uncheckedBounds: (Int(request.requestedOffset), Int(request.requestedOffset) + request.requestedLength))
                    let part = data.subdata(in: range)
                    request.respond(with: part)
                }
                loadingRequest.finishLoading()
            }
            return true
        }
        return false
    }
 */
}
