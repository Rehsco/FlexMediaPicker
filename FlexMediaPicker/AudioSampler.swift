//
//  AudioSampler.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 05.11.2017.
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

open class AudioSampler {
    private var powerSamples: [Float] = []
    private var maxPowerSampled: Float = 0

    private var accumulatedSample: Float = 0
    private var numberAccumulatedSamples: Int = 0
    
    public init() {}
    
    open func reset() {
        self.powerSamples = []
        self.maxPowerSampled = 0
        self.accumulatedSample = 0
        self.numberAccumulatedSamples = 0
    }
    
    /// Sampling is accumulated as long as isSamplingIntervalReached == false
    open func addSample(_ sample: Float, isSamplingIntervalReached: Bool) {
        self.accumulatedSample += sample
        self.numberAccumulatedSamples += 1
        
        if isSamplingIntervalReached {
            let accSample = self.accumulatedSample / Float(self.numberAccumulatedSamples)
            if accSample > self.maxPowerSampled {
                self.maxPowerSampled = accSample
            }
            self.powerSamples.append(accSample)
            self.accumulatedSample = 0
            self.numberAccumulatedSamples = 0
        }
    }
    
    open func generateImageFromSamples() -> UIImage? {
        NSLog("max power amp: \(self.maxPowerSampled) in no of samples: \(self.powerSamples.count)")
        let margin: CGFloat = 4
        let vrImageSampleSize = FlexMediaPickerConfiguration.voiceRecordingSampleImageSize
        guard self.powerSamples.count > 0 && self.maxPowerSampled > 0 else {
            return UIImage(color: .white, size: vrImageSampleSize)
        }
        let ampFactor = Float((vrImageSampleSize.height - 2.0 * margin) / 2.0) / self.maxPowerSampled
        let density = Float(vrImageSampleSize.width) / Float(self.powerSamples.count)
        
        // Prepare buckets
        var sampledValues: [Float] = []
        var sampledValueCount: [Int] = []
        for _ in 0..<Int(vrImageSampleSize.width) {
            sampledValues.append(0)
            sampledValueCount.append(0)
        }

        // Bucket values
        for idx in 0..<self.powerSamples.count {
            let sample = powerSamples[idx]
            let svi = Int(Float(idx) * density)
            let nVal = sample * ampFactor
            sampledValues[svi] = sampledValues[svi] + nVal
            sampledValueCount[svi] = sampledValueCount[svi] + 1
        }
        
        // Create image from buckets
        let rect = CGRect(origin: .zero, size: vrImageSampleSize)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        UIColor.white.setFill()
        UIRectFill(rect)
        
        UIColor.black.setFill()
        for idx in 0..<Int(vrImageSampleSize.width) {
            let svc = sampledValueCount[idx]
            if svc > 0 {
                let val = sampledValues[idx]
                let aval = val / Float(svc)
                let barRect = CGRect(x: CGFloat(idx), y: (vrImageSampleSize.height - CGFloat(aval * 2.0)) * 0.5, width: 1.0, height: CGFloat(aval * 2.0))
                UIRectFill(barRect)
            }
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
