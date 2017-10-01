/**
 Based on AssetManager.swift from MIT Licensed ImagePicker from hyperoslo
 */

import Foundation
import UIKit
import Photos

open class AssetManager {
    
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

    open static func fetch(allowsVideo: Bool = false, fetchLimit: Int = 0, _ completion: @escaping (_ assets: [PHAsset]) -> Void) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        
        let fOptions = PHFetchOptions()
        fOptions.fetchLimit = fetchLimit
        
        DispatchQueue.global(qos: .background).async {
            let fetchResult = allowsVideo
                ? PHAsset.fetchAssets(with: fOptions)
                : PHAsset.fetchAssets(with: .image, options: fOptions)
            
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
    
    open static func resolveVideoAsset(_ asset: PHAsset, resolvedURLHandler: @escaping ((URL)->Void)) {
        PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (asset, audioMix, args) in
            let asset = asset as! AVURLAsset
            resolvedURLHandler(asset.url)
        }
    }
}
