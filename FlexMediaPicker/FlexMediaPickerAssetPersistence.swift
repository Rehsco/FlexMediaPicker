//
//  FlexMediaPickerAssetPersistence.swift
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
import CoreLocation

public protocol FlexMediaPickerAssetPersistence {

    func createVideoRecordAsset(thumbnail: UIImage, videoUrl: URL) -> FlexMediaPickerAsset
    func createAudioRecordAsset(thumbnail: UIImage, audioUrl: URL) -> FlexMediaPickerAsset
    func createLocationAsset(thumbnail: UIImage, location: CLLocation) -> FlexMediaPickerAsset

    func createImageAsset(thumbnail: UIImage, image: UIImage) -> FlexMediaPickerAsset
    func createAssetCollectionAsset(thumbnail: UIImage, asset: PHAsset) -> FlexMediaPickerAsset
    
    func deleteImageAsset(withID id: String)

    func imageFromAsset(withID id: String) -> UIImage?
    
    func isVideoRecorderCreated() -> Bool
    func startRecordVideo(height:Int, width:Int, channels:Int, samples:Float64)
    func writeVideoData(sample: CMSampleBuffer, isVideo: Bool)
    func stopRecordVideo(finishedHandler: @escaping ((FlexMediaPickerAsset?)->Void))
    func encodeVideo(_ videoURL: URL, fromTime: CMTime?, duration: CMTime?, presetName: String, progressHandler: ((Float)->Void)?, exportFinishedHandler: @escaping ((URL?)->Void))

    func startAudioRecording() -> Bool
    func updateAudioMeter() -> (Float, TimeInterval)
    func stopAudioRecording(_ success: Bool, finishedHandler: @escaping ((FlexMediaPickerAsset?)->Void))
    func pauseAudioRecording()
    func resumeAudioRecording()
    func cropAudio(_ audioURL: URL, fromTime: CMTime?, duration: CMTime?, progressHandler: ((Float)->Void)?, exportFinishedHandler: @escaping ((URL?)->Void))

    func numberOfAssets() -> Int
    func getAllAssets() -> [FlexMediaPickerAsset]
    func getAsset(forLocalIdentifier id: String) -> FlexMediaPickerAsset?
    func getAsset(forID id: String) -> FlexMediaPickerAsset?
    
    func deleteAllMedia()
}
