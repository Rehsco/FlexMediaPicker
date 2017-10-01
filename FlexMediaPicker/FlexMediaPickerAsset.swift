//
//  FlexMediaPickerAsset.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 26.08.2017.
//  Copyright © 2017 Martin Jacob Rehder. All rights reserved.
//

import UIKit
import Photos

class FlexMediaPickerAsset {
    let thumbnail: UIImage
    var image: UIImage?
    var asset: PHAsset?
    var collection: PHAssetCollection?
    
    /// Video
    var videoURL: URL?
    var currentFrame: Float64 = 1
    
    init(thumbnail: UIImage, asset: PHAsset, collection: PHAssetCollection) {
        self.thumbnail = thumbnail
        self.asset = asset
        self.collection = collection
    }

    init(thumbnail: UIImage, image: UIImage) {
        self.thumbnail = thumbnail
        self.image = image
    }

    init(thumbnail: UIImage, videoURL: URL) {
        self.thumbnail = thumbnail
        self.videoURL = videoURL
    }
}
