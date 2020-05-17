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
import DSWaveformImage

class ImageAssetImageSource: InputSource {
    var hasFetchedImage: Bool = false
    var imageViewRef: UIImageView?
    var asset: FlexMediaPickerAsset
    let waveformImageDrawer = WaveformImageDrawer()
    
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
            if !self.asset.isVideo(), let image = FlexMediaPickerAssetManager.persistence.imageFromAsset(withID: self.asset.uuid) {
                completionHandler(image)
            }
            else if let ass = self.asset.asset, ass.mediaType == .video {
                FlexMediaPickerAssetManager.resolveVideoAsset(ass, resolvedURLHandler: { url in
                    self.frameImageFromVideo(url: url, completionHandler: completionHandler)
                })
            }
            else if let url = self.asset.videoURL {
                self.frameImageFromVideo(url: url, completionHandler: completionHandler)
            }
            else if let ass = self.asset.asset {
                let images = FlexMediaPickerAssetManager.resolveAssets([ass])
                if let image = images.first {
                    completionHandler(image)
                }
            }
            else if self.asset.isAudio() {
                FlexMediaPickerAssetManager.resolveURL(forMediaAsset: self.asset, resolvedURLHandler: {url in

                    let configuration = WaveformConfiguration(size: UIScreen.main.bounds.size,
                                                              color: FlexMediaPickerConfiguration.recordingWaveformColor,
                                                              style: .gradient,
                                                              position: .middle,
                                                              scale: UIScreen.main.scale,
                                                              paddingFactor: 4.0)
                    self.waveformImageDrawer.waveformImage(fromAudioAt: url, with: configuration) { image in
                        if let thumbnail = image {
                            completionHandler(thumbnail)
                        }
                        else {
                            NSLog("There is no image")
                            completionHandler(self.asset.thumbnail)
                        }
                    }
                })
            }
            else {
                NSLog("There is no image")
                completionHandler(self.asset.thumbnail)
            }
        }
    }
    
    func getVideoURL(completionHandler: @escaping ((URL?)->Void)) {
        if let ass = self.asset.asset, ass.mediaType == .video {
            FlexMediaPickerAssetManager.resolveVideoAsset(ass, resolvedURLHandler: { url in
                completionHandler(url)
            })
        }
        else if let url = self.asset.videoURL {
            completionHandler(url)
        }
        completionHandler(nil)
    }
    
    private func frameImageFromVideo(url: URL, completionHandler: @escaping ((UIImage?)->Void)) {
        self.imageFromVideo(url: url, completionHandler: completionHandler)
    }
    
    func imageFromVideoURL(completionHandler: @escaping ((UIImage?)->Void)) {
        self.getVideoURL { url in
            if let url = url {
                self.imageFromVideo(url: url, completionHandler: completionHandler)
            }
            else {
                completionHandler(nil)
            }
        }
    }
    
    func imageFromVideo(url: URL, completionHandler: @escaping ((UIImage?)->Void)) {
        let asset = AVURLAsset(url: url, options: nil)
        let movieTracks = asset.tracks(withMediaType: AVMediaType.video)
        if let movieTrack = movieTracks.first {
            let durationSeconds = CMTimeGetSeconds(asset.duration)
            let totalFrames: Float64 = durationSeconds * Float64(movieTrack.nominalFrameRate)
            
            DispatchQueue.main.async {
                /// Spool to next available frame
                var returnImage: UIImage? = nil
                var frame = self.asset.currentFrame
                repeat {
                    let secondsIn: Float64 = (frame/totalFrames)*durationSeconds
                    let imageTimeEstimate = CMTimeMakeWithSeconds(secondsIn, preferredTimescale: 600)
                    returnImage = self.videoImage(at: imageTimeEstimate, asset: asset)
                    frame += 1
                } while returnImage == nil && frame <= self.asset.maxFrame
                completionHandler(returnImage)
            }
        }
    }
    
    private func videoImage(at time: CMTime, asset: AVURLAsset) -> UIImage? {
        do {
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.requestedTimeToleranceBefore = CMTime.zero
            imgGenerator.requestedTimeToleranceAfter = CMTime.zero
            imgGenerator.appliesPreferredTrackTransform = true
            var actTime: CMTime = CMTimeMake(value: 0, timescale: 1)
            let cgImage = try imgGenerator.copyCGImage(at: time, actualTime: &actTime)
            let image = UIImage(cgImage: cgImage)
            return image
        } catch _ as NSError {
            // Ignore the error as this can be naturally caused by misaligned audio
//            print("Error generating video image at time \(time): \(error)")
        }
        return nil
    }
    
}
