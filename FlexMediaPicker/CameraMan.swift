/**
 Based on CameraMan.swift from MIT Licensed ImagePicker from hyperoslo
 */

import Foundation
import AVFoundation
import PhotosUI
import AssetsLibrary

protocol CameraManDelegate: class {
    func cameraManDidStart(_ cameraMan: CameraMan)
    func cameraMan(_ cameraMan: CameraMan, didChangeInput input: AVCaptureDeviceInput)
}

class CameraPhotoCapturer: NSObject, AVCapturePhotoCaptureDelegate {
    var didCaptureWithImageData: ((_ imageData: Data) -> Void)?
    var didFinish: (() -> Void)?
    
    func capture(_ output: AVCapturePhotoOutput,
                 didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,
                 previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?) {
        guard let photoSampleBuffer = photoSampleBuffer else {
            if let error = error {
                NSLog("\(#function): \(error)")
            }
            return
        }
        
        if let didCaptureWithImageData = self.didCaptureWithImageData {
            let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)!
            didCaptureWithImageData(imageData)
        }
    }
    
    func capture(_ output: AVCapturePhotoOutput, didFinishCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            NSLog("\(#function): \(error)")
        } else if let didFinish = self.didFinish {
            didFinish()
        }
    }
}

class CameraMan: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    weak var delegate: CameraManDelegate?
    var recordingTimeUpdated: ((TimeInterval)->Void)?
    
    private var startRecordingTime = Date()

    let session = AVCaptureSession()
    let queue = DispatchQueue(label: "org.cocoapods.FlexMediaPicker.Camera.SessionQueue")
    
    // Inputs
    var backCamera: AVCaptureDeviceInput?
    var frontCamera: AVCaptureDeviceInput?
    let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
    
    // Outputs
    var stillImageOutput: AVCapturePhotoOutput?
    var videoOutput: AVCaptureVideoDataOutput?
    fileprivate var currentCapturer: Any?

    // Settings
    var startOnFrontCamera: Bool = false
    fileprivate var _defaultPhotoSettings: Any?
    fileprivate var defaultPhotoSettings: AVCapturePhotoSettings {
        get {
            if _defaultPhotoSettings == nil {
                let photoSettings = AVCapturePhotoSettings()
                photoSettings.isHighResolutionPhotoEnabled = true
                _defaultPhotoSettings = photoSettings
            }
            return _defaultPhotoSettings as! AVCapturePhotoSettings
        }
    }
    
    // Video
    var height:Int?
    var width:Int?
    
    var isCapturing = false
    var isPaused = false
    var isDiscontinue = false
    
    var timeOffset = CMTimeMake(0, 0)
    var lastAudioPts: CMTime?
    
    let lockQueue = DispatchQueue(label: "org.cocoapods.FlexMediaPicker.Camera.LockQueue")
    let recordingQueue = DispatchQueue(label: "org.cocoapods.FlexMediaPicker.Camera.RecordingQueue")
    
    var videoRecordedEventHandler: ((FlexMediaPickerAsset)->Void)?
    
    deinit {
        self.stopVideoRecording()
        self.cleanupVideoOutput()
        self.stop()
    }
    
    // MARK: - Setup
    
    func setup(_ startOnFrontCamera: Bool = false) {
        self.startOnFrontCamera = startOnFrontCamera
        self.start()
    }
    
    func setupDevices() {
        // Input
        self.frontCamera = try? AVCaptureDeviceInput(device: AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front))
        self.backCamera = try? AVCaptureDeviceInput(device: AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back))
        self.currentInput = startOnFrontCamera ? self.frontCamera : self.backCamera
        
        // Output for Photo
        let photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true
        stillImageOutput = photoOutput
        
        // Output for Video
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: recordingQueue)
        videoOutput?.alwaysDiscardsLateVideoFrames = true
        videoOutput?.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        ]
        
        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice) as AVCaptureDeviceInput
            session.addInput(audioInput)
        }
        catch let error as NSError {
            NSLog(error.localizedDescription)
        }
    }
    
    func addInput(_ input: AVCaptureDeviceInput) {
        configurePreset(input)
        
        if session.canAddInput(input) {
            session.addInput(input)
            
            DispatchQueue.main.async {
                self.delegate?.cameraMan(self, didChangeInput: input)
            }
        }
    }

    // MARK: - Session
    
    var currentInput: AVCaptureDeviceInput?
    
    fileprivate func start() {
        // Devices
        setupDevices()
        
        guard let input = (self.startOnFrontCamera) ? frontCamera ?? backCamera : backCamera, let output = stillImageOutput else { return }
        
        addInput(input)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        if let vo = self.videoOutput {
            if session.canAddOutput(vo) {
                self.session.addOutput(vo)
            }
        }

        let audioDataOutput = AVCaptureAudioDataOutput()
        audioDataOutput.setSampleBufferDelegate(self, queue: recordingQueue)
        session.addOutput(audioDataOutput)
        
        queue.async {
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.delegate?.cameraManDidStart(self)
            }
        }
    }
    
    fileprivate func stop() {
        self.session.stopRunning()
    }
    
    func switchCamera(_ completion: (() -> Void)? = nil) {
        guard let currentInput = currentInput
            else {
                completion?()
                return
        }
        
        queue.async {
            guard let input = (currentInput == self.backCamera) ? self.frontCamera : self.backCamera
                else {
                    DispatchQueue.main.async {
                        completion?()
                    }
                    return
            }
            
            self.configure {
                self.session.removeInput(currentInput)
                self.addInput(input)
            }
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func takePhoto(_ previewLayer: AVCaptureVideoPreviewLayer, completion: ((UIImage?) -> Void)? = nil) {
        guard let connection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo) else { return }
        
        connection.videoOrientation = Helper.videoOrientation()
        
        if let photoOutput = self.stillImageOutput, self.currentCapturer == nil {
            self.queue.async {
                let capturer = CameraPhotoCapturer()
                capturer.didCaptureWithImageData = { (imageData) in
                    let image = UIImage(data: imageData)
                    completion?(image)
                }
                capturer.didFinish = { [unowned self] in
                    self.currentCapturer = nil
                }
                let settings = AVCapturePhotoSettings(from: self.defaultPhotoSettings)
                photoOutput.capturePhoto(with: settings, delegate: capturer)
                
                self.currentCapturer = capturer
            }
        }
    }
    
    func startVideoRecording(_ previewLayer: AVCaptureVideoPreviewLayer) {
        guard let connection = videoOutput?.connection(withMediaType: AVMediaTypeVideo) else { return }
        connection.videoOrientation = Helper.videoOrientation()

        self.startRecordingTime = Date()
        self.recordingTimeUpdated?(self.startRecordingTime.timeIntervalSinceNow)
        
        height = videoOutput?.videoSettings["Height"] as! Int!
        width = videoOutput?.videoSettings["Width"] as! Int!

        lockQueue.sync() {
            if !self.isCapturing{
                self.isPaused = false
                self.isDiscontinue = false
                self.isCapturing = true
                self.timeOffset = CMTimeMake(0, 0)
            }
        }
    }
    
    func stopVideoRecording() {
        self.lockQueue.sync() {
            if self.isCapturing{
                self.isCapturing = false
                DispatchQueue.main.async {
                    AssetManager.persistence.stopRecordVideo() {
                        mpa in
                        NSLog("Recording finished.")
                        if let mpa = mpa {
                            self.videoRecordedEventHandler?(mpa)
                        }
                    }
                }
            }
        }
    }
    
    func pauseVideo() {
        self.lockQueue.sync() {
            if self.isCapturing{
                NSLog("pause video")
                self.isPaused = true
                self.isDiscontinue = true
            }
        }
    }
    
    func resumeVideo() {
        self.lockQueue.sync() {
            if self.isCapturing{
                NSLog("resume video")
                self.isPaused = false
            }
        }
    }
    
    func cleanupVideoOutput() {
        if let vo = self.videoOutput {
            self.session.removeOutput(vo)
        }
    }
    
    // MARK: - Capturing
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        // Intentionally left blank
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        let time = Date().timeIntervalSinceNow - self.startRecordingTime.timeIntervalSinceNow
        self.lockQueue.sync() {
            if !self.isCapturing || self.isPaused {
                return
            }
            self.recordingTimeUpdated?(time)

            let isVideo = captureOutput is AVCaptureVideoDataOutput
            
            if !AssetManager.persistence.isVideoRecorderCreated() && !isVideo {
                let fmt = CMSampleBufferGetFormatDescription(sampleBuffer)
                let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt!)
                
                AssetManager.persistence.startRecordVideo(
                    height: self.height!, width: self.width!,
                    channels: Int((asbd?.pointee.mChannelsPerFrame)!),
                    samples: (asbd?.pointee.mSampleRate)!
                )
            }
            
            if self.isDiscontinue {
                if isVideo {
                    return
                }
                
                var pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                
                let isAudioPtsValid = self.lastAudioPts!.flags.intersection(CMTimeFlags.valid)
                if isAudioPtsValid.rawValue != 0 {
                    NSLog("isAudioPtsValid is valid")
                    let isTimeOffsetPtsValid = self.timeOffset.flags.intersection(CMTimeFlags.valid)
                    if isTimeOffsetPtsValid.rawValue != 0 {
                        NSLog("isTimeOffsetPtsValid is valid")
                        pts = CMTimeSubtract(pts, self.timeOffset)
                    }
                    let offset = CMTimeSubtract(pts, self.lastAudioPts!)
                    
                    if (self.timeOffset.value == 0)
                    {
                        NSLog("timeOffset is \(self.timeOffset.value)")
                        self.timeOffset = offset
                    }
                    else
                    {
                        NSLog("timeOffset is \(self.timeOffset.value)")
                        self.timeOffset = CMTimeAdd(self.timeOffset, offset)
                    }
                }
                self.lastAudioPts!.flags = CMTimeFlags()
                self.isDiscontinue = false
            }
            
            var buffer = sampleBuffer
            if self.timeOffset.value > 0 {
                buffer = self.ajustTimeStamp(sample: sampleBuffer, offset: self.timeOffset)
            }
            
            if !isVideo {
                var pts = CMSampleBufferGetPresentationTimeStamp(buffer!)
                let dur = CMSampleBufferGetDuration(buffer!)
                if (dur.value > 0) {
                    pts = CMTimeAdd(pts, dur)
                }
                self.lastAudioPts = pts
            }

            if let buf = buffer {
                AssetManager.persistence.writeVideoData(sample: buf, isVideo: isVideo)
            }
        }
        if FlexMediaPickerConfiguration.maxVideoRecordingTime > 0 && time >= FlexMediaPickerConfiguration.maxVideoRecordingTime  && self.isCapturing {
            self.stopVideoRecording()
            AlertViewFactory.showFailAlert(title: FlexMediaPickerConfiguration.recordingEndedTitle, message: FlexMediaPickerConfiguration.recordingEndedMessage, iconName: FlexMediaPickerConfiguration.alertIconName)
        }
    }
    
    func ajustTimeStamp(sample: CMSampleBuffer, offset: CMTime) -> CMSampleBuffer {
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
        var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: CMTimeMake(0, 0), presentationTimeStamp: CMTimeMake(0, 0), decodeTimeStamp: CMTimeMake(0, 0)), count: count)
        CMSampleBufferGetSampleTimingInfoArray(sample, count, &info, &count);
        
        for i in 0..<count {
            info[i].decodeTimeStamp = CMTimeSubtract(info[i].decodeTimeStamp, offset);
            info[i].presentationTimeStamp = CMTimeSubtract(info[i].presentationTimeStamp, offset);
        }
        
        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, &info, &out);
        return out!
    }
    
    func flash(_ mode: AVCaptureFlashMode) {
        if let currentDevice = self.currentInput?.device, let captureOutput = self.stillImageOutput, currentDevice.isFlashAvailable  {
            let isFlashModeSupported = captureOutput.__supportedFlashModes.contains(NSNumber(value: mode.rawValue))
            if isFlashModeSupported {
                self.defaultPhotoSettings.flashMode = mode
            }
        }
    }
    
    func focus(_ point: CGPoint) {
        guard let device = currentInput?.device, device.isFocusModeSupported(AVCaptureFocusMode.locked) else { return }
        
        queue.async {
            self.lock {
                device.focusPointOfInterest = point
            }
        }
    }
    
    func zoom(_ zoomFactor: CGFloat) {
        guard let device = currentInput?.device, device.position == .back else { return }
        
        queue.async {
            self.lock {
                device.videoZoomFactor = zoomFactor
            }
        }
    }
    
    // MARK: - Lock
    
    func lock(_ block: () -> Void) {
        if let device = currentInput?.device, (try? device.lockForConfiguration()) != nil {
            block()
            device.unlockForConfiguration()
        }
    }
    
    // MARK: - Configure
    
    func configure(_ block: () -> Void) {
        session.beginConfiguration()
        block()
        session.commitConfiguration()
    }
    
    // MARK: - Preset
    
    func configurePreset(_ input: AVCaptureDeviceInput) {
        for asset in preferredPresets() {
            if input.device.supportsAVCaptureSessionPreset(asset) && self.session.canSetSessionPreset(asset) {
                self.session.sessionPreset = asset
                return
            }
        }
    }
    
    func preferredPresets() -> [String] {
        return [
            AVCaptureSessionPresetHigh,
            AVCaptureSessionPresetMedium,
            AVCaptureSessionPresetLow
        ]
    }
}
