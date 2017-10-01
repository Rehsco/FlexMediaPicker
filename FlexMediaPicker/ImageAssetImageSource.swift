//
//  ImageAssetImageSource.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 13.07.2017.
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
import ImageSlideshow
import AVFoundation

class ImageAssetImageSource: InputSource {
    var hasFetchedImage: Bool = false
    var imageViewRef: UIImageView?
    var asset: FlexMediaPickerAsset
    
    var imageFromVideoLoadedHandler: ((FlexMediaPickerAsset)->Void)?
    
    init(asset: FlexMediaPickerAsset) {
        self.asset = asset
    }
    
    func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        self.imageViewRef = imageView
        DispatchQueue.main.async {
            imageView.image = self.asset.thumbnail
        }
        self.downloadOrFetchImage() {
            image in
            self.hasFetchedImage = true
            DispatchQueue.main.async {
                callback(image)
            }
        }
    }

    private func downloadOrFetchImage(completionHandler: @escaping ((UIImage?)->Void)) {
        DispatchQueue.main.async {
            if let image = self.asset.image {
                completionHandler(image)
            }
            else if let ass = self.asset.asset, ass.mediaType == .video {
                AssetManager.resolveVideoAsset(ass, resolvedURLHandler: { url in
                    self.frameImageFromVideo(url: url, completionHandler: completionHandler)
                })
            }
            else if let url = self.asset.videoURL {
                self.frameImageFromVideo(url: url, completionHandler: completionHandler)
            }
            else if let ass = self.asset.asset {
                let images = AssetManager.resolveAssets([ass])
                if let image = images.first {
                    completionHandler(image)
                }
            }
            else {
                NSLog("There is no image")
                completionHandler(self.asset.thumbnail)
            }
        }
    }
    
    func getVideoURL(completionHandler: @escaping ((URL?)->Void)) {
        if let ass = self.asset.asset, ass.mediaType == .video {
            AssetManager.resolveVideoAsset(ass, resolvedURLHandler: { url in
                completionHandler(url)
            })
        }
        else if let url = self.asset.videoURL {
            completionHandler(url)
        }
        completionHandler(nil)
    }
    
    private func frameImageFromVideo(url: URL, completionHandler: @escaping ((UIImage?)->Void)) {
        if let image = self.imageFromVideo(url: url) {
            completionHandler(image)
            self.imageFromVideoLoadedHandler?(self.asset)
        }
    }
    
    func imageFromVideo(url: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: url, options: nil)
            let movieTracks = asset.tracks(withMediaType: AVMediaTypeVideo)
            if let movieTrack = movieTracks.first {
                let durationSeconds = CMTimeGetSeconds(asset.duration)
                let totalFrames: Float64 = durationSeconds * Float64(movieTrack.nominalFrameRate)
                
                let secondsIn: Float64 = (self.asset.currentFrame/totalFrames)*durationSeconds
                let imageTimeEstimate: CMTime = CMTimeMakeWithSeconds(secondsIn, 600)
                NSLog("Getting image frame at time \(imageTimeEstimate)")
                
                let imgGenerator = AVAssetImageGenerator(asset: asset)
                imgGenerator.appliesPreferredTrackTransform = true
                let cgImage = try imgGenerator.copyCGImage(at: imageTimeEstimate, actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                return image
            }
        } catch let error as NSError {
            print("Error generating video image: \(error)")
        }
        return nil
    }
    
}
