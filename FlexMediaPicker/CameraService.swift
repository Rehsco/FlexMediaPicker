//
//  CameraService.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 06.11.2017.
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
import AVFoundation

let cameraService = CameraService()

open class CameraService: NSObject {
    
    func checkPermission(permissionGrantedHandler: @escaping (Bool)->Void) {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch status {
        case .authorized:
            permissionGrantedHandler(true)
        case .denied, .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
                if granted {
                    permissionGrantedHandler(true)
                } else {
                    AlertViewFactory.showSettingsRequest(title: FlexMediaPickerConfiguration.requestPermissionTitle, message: FlexMediaPickerConfiguration.requestCameraPermissionMessage)
                    permissionGrantedHandler(false)
                }
            }
        default:
            permissionGrantedHandler(false)
        }
    }
}
