/**
 Based on AssetManager.swift from MIT Licensed ImagePicker from hyperoslo
 */

import Foundation
import UIKit
import Photos

open class AssetManager {
    /// Replace this with own persistence management, if required
    public static var persistence: FlexMediaPickerAssetPersistence = FlexMediaPickerAssetPersistenceImpl()
    
    open static func getImage(_ name: String) -> UIImage {
        return UIImage(named: name, in: Bundle(for: AssetManager.self), compatibleWith: nil) ?? UIImage()
    }
    
    open static func fetchAssetCollections(_ completion: @escaping (_ assetCollections: [PHAssetCollection]) -> Void) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        
        DispatchQueue.global(qos: .background).async {
            let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            
            if fetchResult.count > 0 {
                var assets = [PHAssetCollection]()
                fetchResult.enumerateObjects({ object, _, _ in
                    if object.estimatedAssetCount > 0 {
                        assets.append(object)
                    }
                })
                
                DispatchQueue.main.async {
                    completion(assets)
                }
            }
        }
    }
    
    open static func fetchSmartAssetCollections(_ completion: @escaping (_ assetCollections: [PHAssetCollection]) -> Void) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        
        DispatchQueue.global(qos: .background).async {
            let fetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
            
            if fetchResult.count > 0 {
                var assets = [PHAssetCollection]()
                fetchResult.enumerateObjects({ object, _, _ in
                    if object.estimatedAssetCount > 0 {
                        assets.append(object)
                    }
                })
                
                DispatchQueue.main.async {
                    completion(assets)
                }
            }
        }
    }
    
    open static func fetch(in collection: PHAssetCollection, fetchLimit: Int = 0, _ completion: @escaping (_ assets: [PHAsset]) -> Void) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        
        let fOptions = PHFetchOptions()
        fOptions.fetchLimit = fetchLimit
        
        DispatchQueue.global(qos: .background).async {
            let fetchResult = PHAsset.fetchAssets(in: collection, options: fOptions)
            
            if fetchResult.count > 0 {
                var assets = [PHAsset]()
                fetchResult.enumerateObjects({ object, _, _ in
                    assets.append(object)
                })
                
                DispatchQueue.main.async {
                    completion(assets)
                }
            }
        }
    }

    open static func resolveAsset(_ asset: PHAsset, size: CGSize = CGSize(width: 720, height: 1280), completion: @escaping (_ image: UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        
        imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, info in
            if let info = info, info["PHImageFileUTIKey"] == nil {
                DispatchQueue.main.async(execute: {
                    completion(image)
                })
            }
        }
    }
    
    open static func resolveAssets(_ assets: [PHAsset], size: CGSize = CGSize(width: 720, height: 1280)) -> [UIImage] {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        var images = [UIImage]()
        for asset in assets {
            imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, _ in
                if let image = image {
                    NSLog("Image found by PHImageManager for id \(asset.localIdentifier). Size = \(image.size)")
                    images.append(image)
                }
            }
        }
        return images
    }
    
    open static func resolveURL(forMediaAsset mpa: FlexMediaPickerAsset, resolvedURLHandler: @escaping ((URL)->Void)) {
        if let asset = mpa.asset {
            if asset.mediaType == .video {
                self.resolveVideoAsset(asset, resolvedURLHandler: resolvedURLHandler)
            }
        }
        else if let url = mpa.videoURL {
            resolvedURLHandler(url)
        }
        else if let url = mpa.audioURL {
            resolvedURLHandler(url)
        }
    }

    open static func isAssetSelected(_ asset: PHAsset) -> Bool {
        let selectedAssets = self.persistence.getAllAssets()
        for ass in selectedAssets {
            if let pha = ass.asset {
                if pha.localIdentifier == asset.localIdentifier {
                    return true
                }
            }
        }
        return false
    }
    
    open static func getAcceptableAssetCount() -> Int {
        var numApplicableSelected = 0
        let allSelectedAssets = self.persistence.getAllAssets()
        for sa in allSelectedAssets {
            if sa.isVideo() {
                if FlexMediaPickerConfiguration.allowVideoSelection {
                    numApplicableSelected += 1
                }
            }
            else if sa.isAudio() {
                if FlexMediaPickerConfiguration.allowVoiceRecording {
                    numApplicableSelected += 1
                }
            }
            else {
                numApplicableSelected += 1
            }
        }
        return numApplicableSelected
    }
    
    open static func getAcceptedAssets() -> [FlexMediaPickerAsset] {
        var returnableAssets: [FlexMediaPickerAsset] = []
        let allSelectedAssets = self.persistence.getAllAssets()
        for sa in allSelectedAssets {
            if sa.isVideo() {
                if FlexMediaPickerConfiguration.allowVideoSelection {
                    returnableAssets.append(sa)
                }
            }
            else if sa.isAudio() {
                if FlexMediaPickerConfiguration.allowVoiceRecording {
                    returnableAssets.append(sa)
                }
            }
            else {
                returnableAssets.append(sa)
            }
        }
        return returnableAssets
    }
    
    open static func resolveVideoAsset(_ asset: PHAsset, resolvedURLHandler: @escaping ((URL)->Void)) {
        PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (asset, audioMix, args) in
            if let asset = asset as? AVURLAsset {
                resolvedURLHandler(asset.url)
            }
        }
    }

    open static func savePhoto(_ image: UIImage, location: CLLocation?, completion: ((PHAsset?) -> Void)? = nil) {
        func retrieveImageWithIdentifer(localIdentifier:String, completion: (PHAsset?) -> Void) {
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: fetchOptions)
            
            if fetchResults.count > 0 {
                if let imageAsset = fetchResults.firstObject {
                    completion(imageAsset)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
        
        var imageIdentifier: String?
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            request.creationDate = Date()
            request.location = location
            let placeholder = request.placeholderForCreatedAsset
            imageIdentifier = placeholder?.localIdentifier
        }, completionHandler: { success, error in
            if success, let locId = imageIdentifier  {
                DispatchQueue.main.async {
                    retrieveImageWithIdentifer(localIdentifier: locId, completion: { asset in
                        completion?(asset)
                    })
                }
            }
            else {
                NSLog("\(#function): Could not store image to photos. \(error.debugDescription)")
            }
        })
    }
    
    open class func storeVideo(forURL url: URL, completion: ((PHAsset?) -> Void)? = nil) {
        func retrieveVideoWithIdentifer(localIdentifier:String, completion: (PHAsset?) -> Void) {
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            let fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: fetchOptions)
            
            if fetchResults.count > 0 {
                if let videoAsset = fetchResults.firstObject {
                    completion(videoAsset)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
        
        var videoIdentifier: String?
        PHPhotoLibrary.shared().performChanges({
            if let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) {
                let placeholder = request.placeholderForCreatedAsset
                videoIdentifier = placeholder?.localIdentifier
            }
        }) { saved, error in
            if saved, let vid = videoIdentifier {
                NSLog("Transfer video to library finished.")
                retrieveVideoWithIdentifer(localIdentifier: vid, completion: { videoAsset in
                    completion?(videoAsset)
                })
            }
            else {
                NSLog("Could not store video")
                completion?(nil)
            }
        }
    }
    
    open static func reencodeVideo(forMediaAsset mpa: FlexMediaPickerAsset, progressHandler: ((Float)->Void)? = nil, completedURLHandler: @escaping ((URL)->Void)) {
        AssetManager.resolveURL(forMediaAsset: mpa) { url in
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
            let fileURL = documentsDirectory.appendingPathComponent("\(mpa.uuid).mp4")
            let startOffset = self.getTimeForVideoFrame(mpa.minFrame, videoURL: url)
            let endOffset = self.getTimeForVideoFrame(mpa.maxFrame, videoURL: url)
            let duration = endOffset - startOffset
            self.persistence.encodeVideo(url, targetURL: fileURL, fromTime: startOffset, duration: duration, presetName: FlexMediaPickerConfiguration.videoOutputFormat, progressHandler: progressHandler, exportFinishedHandler: { url in
                if let videoUrl = url {
                    completedURLHandler(videoUrl)
                }
            })
        }
    }

    open static func cropAudio(forMediaAsset mpa: FlexMediaPickerAsset, progressHandler: ((Float)->Void)? = nil, completedURLHandler: @escaping ((URL)->Void)) {
        AssetManager.resolveURL(forMediaAsset: mpa) { url in
            let asset = AVURLAsset(url: url)
            let dur = asset.duration
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
            let fileURL = documentsDirectory.appendingPathComponent("\(mpa.uuid).m4a")
            let startOffset = CMTimeMakeWithSeconds(mpa.minTimeOffset * dur.seconds, dur.timescale)
            let endOffset = CMTimeMakeWithSeconds(mpa.maxTimeOffset * dur.seconds, dur.timescale)
            let duration = endOffset - startOffset
            self.persistence.cropAudio(url, targetURL: fileURL, fromTime: startOffset, duration: duration, progressHandler: progressHandler, exportFinishedHandler: { url in
                if let videoUrl = url {
                    completedURLHandler(videoUrl)
                }
            })
        }
    }

    // Helper
    
    open class func duration(forMediaAsset mpa: FlexMediaPickerAsset, durationHandler: @escaping ((Float)->Void)) {
        AssetManager.resolveURL(forMediaAsset: mpa) { url in
            let asset = AVURLAsset(url: url)
            let duration = asset.duration
            let durationSeconds = CMTimeGetSeconds(duration)
            durationHandler(Float(durationSeconds))
        }
    }
    
    open class func getTimeForVideoFrame(_ frame: Float64, videoURL: URL) -> CMTime {
        let asset = AVURLAsset(url: videoURL, options: nil)
        let movieTracks = asset.tracks(withMediaType: AVMediaTypeVideo)
        if let movieTrack = movieTracks.first {
            let durationSeconds = CMTimeGetSeconds(asset.duration)
            let totalFrames: Float64 = durationSeconds * Float64(movieTrack.nominalFrameRate)
            let time64 = (frame / totalFrames) * durationSeconds
            return CMTimeMakeWithSeconds(time64, 600)
        }
        return CMTimeMakeWithSeconds(0.0, 0)        
    }
    
    open class func getVideoFrameForTime(_ time: TimeInterval, movieAsset: AVURLAsset?) -> Float64 {
        if let asset = movieAsset {
            let movieTracks = asset.tracks(withMediaType: AVMediaTypeVideo)
            if let movieTrack = movieTracks.first {
                let durationSeconds = CMTimeGetSeconds(asset.duration)
                let totalFrames: Float64 = durationSeconds * Float64(movieTrack.nominalFrameRate)
                let frame: Float64 = Float64(time) / Float64(durationSeconds) * totalFrames
                return frame
            }
        }
        return 0
    }

    open class func getThumbnailForVideoAsset(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        if let cgImage = try? imgGenerator.copyCGImage(at: CMTimeMake(5, 1), actualTime: nil) {
            let image = UIImage(cgImage: cgImage)
            let thImageSize = FlexMediaPickerConfiguration.thumbnailSize
            return image.scaleToSizeKeepAspect(size: thImageSize)
        }
        return nil
    }
}
