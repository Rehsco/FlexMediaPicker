/**
 Based on CameraView.swift from MIT Licensed ImagePicker from hyperoslo
 */

import UIKit
import AVFoundation
import PhotosUI
import MJRFlexStyleComponents

protocol CameraViewDelegate: class {
    func cameraNotAvailable()
}

class CameraView: FlexView, CameraManDelegate {
    private var videoCamRecording: Bool = false
    private var recordingInfoLabel: FlexLabel?

    var cameraControlPanel = CameraMediaControlPanel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    override var footer: FlexFooterView {
        return self.cameraControlPanel
    }
    
    lazy var blurView: UIVisualEffectView = { [unowned self] in
        let effect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: effect)
        
        return blurView
        }()
    
    lazy var focusImageView: UIImageView = { [unowned self] in
        let imageView = UIImageView()
        imageView.image = AssetManager.getImage("focusIcon")
        imageView.backgroundColor = UIColor.clear
        imageView.frame = CGRect(x: 0, y: 0, width: 110, height: 110)
        imageView.alpha = 0
        
        return imageView
        }()
    
    lazy var capturedImageView: UIView = { [unowned self] in
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.alpha = 0
        
        return view
        }()
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.alpha = 0
        
        return view
    }()

    lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(tapGestureRecognizerHandler(_:)))
        
        return gesture
        }()
    
    lazy var pinchGestureRecognizer: UIPinchGestureRecognizer = { [unowned self] in
        let gesture = UIPinchGestureRecognizer()
        gesture.addTarget(self, action: #selector(pinchGestureRecognizerHandler(_:)))
        
        return gesture
        }()
    
    let cameraMan = CameraMan()
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: CameraViewDelegate?
    var animationTimer: Timer?
    var startOnFrontCamera: Bool = false
    
    var didGetPhoto: ((UIImage, CLLocation?)->Void)?
    var didRecordVideo: ((FlexMediaPickerAsset)->Void)?
    var cancelCameraViewHandler: (()->Void)?
    
    private let minimumZoomFactor: CGFloat = 1.0
    private let maximumZoomFactor: CGFloat = 3.0
    
    private var currentZoomFactor: CGFloat = 1.0
    private var previousZoomFactor: CGFloat = 1.0
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.backgroundColor = FlexMediaPickerConfiguration.styleColor
        
        self.addSubview(containerView)
        containerView.addSubview(blurView)
        
        [focusImageView, capturedImageView].forEach {
            self.addSubview($0)
        }
        
        self.addGestureRecognizer(tapGestureRecognizer)
        
        if FlexMediaPickerConfiguration.allowPinchToZoom {
            self.addGestureRecognizer(pinchGestureRecognizer)
        }
        
        cameraMan.delegate = self
        cameraMan.setup(self.startOnFrontCamera)
        
        cameraMan.videoRecordedEventHandler = {
            mpa in
            DispatchQueue.main.async {
                self.didRecordVideo?(mpa)
                self.cameraControlPanel.isVideoModeActive = false
                self.cameraControlPanel.applyTriggerButtonStyle()
            }
        }
        cameraMan.recordingTimeUpdated = {
            timeElapsed in
            DispatchQueue.main.async {
                self.recordingInfoLabel?.label.text = Helper.stringFromTimeInterval(interval: timeElapsed)
                if FlexMediaPickerConfiguration.maxVideoRecordingTime > 0 {
                    if FlexMediaPickerConfiguration.maxVideoRecordingTime - timeElapsed <= FlexMediaPickerConfiguration.secondWarningForRecordingLimitAtTimeLeft {
                        self.recordingInfoLabel?.labelTextColor = FlexMediaPickerConfiguration.secondWarningOfRecordingTimeColor
                    }
                    else if FlexMediaPickerConfiguration.maxVideoRecordingTime - timeElapsed <= FlexMediaPickerConfiguration.firstWarningForRecordingLimitAtTimeLeft {
                        self.recordingInfoLabel?.labelTextColor = FlexMediaPickerConfiguration.firstWarningOfRecordingTimeColor
                    }
                    else {
                        self.recordingInfoLabel?.labelTextColor = FlexMediaPickerConfiguration.headerTextColor
                    }
                }
                self.recordingInfoLabel?.setNeedsLayout()
            }
        }

        self.headerSize = FlexMediaPickerConfiguration.headerHeight
        self.header.styleColor = .clear
        
        self.recordingInfoLabel = FlexLabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.recordingInfoLabel?.labelTextColor = FlexMediaPickerConfiguration.headerTextColor
        self.recordingInfoLabel?.labelFont = FlexMediaPickerConfiguration.headerFont
        self.recordingInfoLabel?.labelTextAlignment = .center
        self.recordingInfoLabel?.isHidden = true
        self.addSubview(self.recordingInfoLabel!)

        self.footerSize = FlexMediaPickerConfiguration.footerHeight
        self.footerText = " "
        if let ccp = self.footer as? CameraMediaControlPanel {
            ccp.setupMenu(in: self)
            
            ccp.takePhotoActionHandler = {
                self.takePicture { image, location in
                    if let img = image {
                        self.didGetPhoto?(img, location)
                    }
                }
            }
            ccp.recVideoActionHandler = {
                if self.videoCamRecording {
                    self.videoCamRecording = false
                    self.recordingInfoLabel?.isHidden = true
                    self.stopVideoRecording()
                }
                else {
                    self.videoCamRecording = true
                    self.recordingInfoLabel?.isHidden = false
                    self.startVideoRecording()
                }

            }
            ccp.cameraSwitchActionHandler = {
                self.rotateCamera()
            }
            ccp.flashActionHandler = { mode in
                let flashMode = mode ? AVCaptureFlashMode.on : AVCaptureFlashMode.off
                self.flashCamera(flashMode)
            }
            ccp.backToImagesHandler = {
                self.closeView()
                self.cancelCameraViewHandler?()
            }
        }
    }
    
    public func displayView() {
        previewLayer?.connection.videoOrientation = Helper.videoOrientation()
        if FlexMediaPickerConfiguration.recordLocationOnPhoto {
            locationService.startLocationMessagingUse()
        }
    }

    public func closeView() {
    }
    
    private func setupPreviewLayer() {
        self.previewLayer?.removeFromSuperlayer()
        guard let layer = AVCaptureVideoPreviewLayer(session: cameraMan.session) else { return }
        
        layer.backgroundColor = FlexMediaPickerConfiguration.styleColor.cgColor
        layer.autoreverses = true
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        self.layer.insertSublayer(layer, at: 1)
        layer.frame = self.layer.frame
        self.clipsToBounds = true
        
        previewLayer = layer
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let bb = self.getViewRect()
        
        blurView.frame = bb
        containerView.frame = bb
        capturedImageView.frame = bb
        self.previewLayer?.frame = bb
        
        previewLayer?.connection.videoOrientation = Helper.videoOrientation()
        var yoff:CGFloat = 0
        if #available(iOS 11, *) {
            yoff = self.safeAreaInsets.top
        }
        self.recordingInfoLabel?.frame = CGRect(x: 0, y: yoff, width: self.bounds.size.width, height: FlexMediaPickerConfiguration.headerHeight)
    }
    
    // MARK: - Camera actions
    
    func rotateCamera() {
        UIView.animate(withDuration: 0.3, animations: { _ in
            self.containerView.alpha = 1
        }, completion: { _ in
            self.cameraMan.switchCamera {
                UIView.animate(withDuration: 0.7, animations: {
                    self.containerView.alpha = 0
                })
            }
        })
    }
    
    func flashCamera(_ mode: AVCaptureFlashMode) {
        cameraMan.flash(mode)
    }
    
    private func takePicture(_ completion: @escaping (UIImage?, CLLocation?) -> Void) {
        guard let previewLayer = previewLayer else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.capturedImageView.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.capturedImageView.alpha = 0
            })
        })
        
        cameraMan.takePhoto(previewLayer) { image in
            if FlexMediaPickerConfiguration.recordLocationOnPhoto {
                completion(image, locationService.currentLocation)
            }
            else {
                completion(image, nil)
            }
        }
    }
    
    private func startVideoRecording() {
        guard let previewLayer = previewLayer else { return }
        cameraMan.startVideoRecording(previewLayer)
    }
    
    private func stopVideoRecording() {
        cameraMan.stopVideoRecording()
    }
    
    // MARK: - Timer methods
    
    func timerDidFire() {
        UIView.animate(withDuration: 0.3, animations: { [unowned self] in
            self.focusImageView.alpha = 0
            }, completion: { _ in
                self.focusImageView.transform = CGAffineTransform.identity
        })
    }
    
    // MARK: - Camera methods
    
    func focusTo(_ point: CGPoint) {
        let convertedPoint = CGPoint(x: point.x / UIScreen.main.bounds.width,
                                     y:point.y / UIScreen.main.bounds.height)
        
        cameraMan.focus(convertedPoint)
        
        focusImageView.center = point
        UIView.animate(withDuration: 0.5, animations: { _ in
            self.focusImageView.alpha = 1
            self.focusImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }, completion: { _ in
            self.animationTimer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                                       selector: #selector(CameraView.timerDidFire), userInfo: nil, repeats: false)
        })
    }
    
    func zoomTo(_ zoomFactor: CGFloat) {
        guard let device = cameraMan.currentInput?.device else { return }
        
        let maximumDeviceZoomFactor = device.activeFormat.videoMaxZoomFactor
        let newZoomFactor = previousZoomFactor * zoomFactor
        currentZoomFactor = min(maximumZoomFactor, max(minimumZoomFactor, min(newZoomFactor, maximumDeviceZoomFactor)))
        
        cameraMan.zoom(currentZoomFactor)
    }
    
    // MARK: - Tap
    
    func tapGestureRecognizerHandler(_ gesture: UITapGestureRecognizer) {
        let touch = gesture.location(in: self)
        
        focusImageView.transform = CGAffineTransform.identity
        animationTimer?.invalidate()
        focusTo(touch)
    }
    
    // MARK: - Pinch
    
    func pinchGestureRecognizerHandler(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            fallthrough
        case .changed:
            zoomTo(gesture.scale)
        case .ended:
            zoomTo(gesture.scale)
            previousZoomFactor = currentZoomFactor
        default: break
        }
    }
    
    // MARK: - Private helpers
    
    func cameraMan(_ cameraMan: CameraMan, didChangeInput input: AVCaptureDeviceInput) {
/*        if !FlexMediaPickerConfiguration.flashButtonAlwaysHidden {
            delegate?.setFlashButtonHidden(!input.device.hasFlash)
        }
 */
    }
    
    func cameraManDidStart(_ cameraMan: CameraMan) {
        setupPreviewLayer()
    }
}
