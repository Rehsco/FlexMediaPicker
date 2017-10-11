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
                    images.append(image)
                }
            }
        }
        return images
    }
    
    open static func resolveVideoURL(forMediaAsset mpa: FlexMediaPickerAsset, resolvedURLHandler: @escaping ((URL)->Void)) {
        if let asset = mpa.asset {
            self.resolveVideoAsset(asset, resolvedURLHandler: resolvedURLHandler)
        }
        else if let url = mpa.videoURL {
            resolvedURLHandler(url)
        }
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
    
    // Helper
    
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
