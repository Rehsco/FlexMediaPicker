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

class CameraView: FlexView, CLLocationManagerDelegate, CameraManDelegate {
    private var videoCamRecording: Bool = false

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
    
    lazy var noCameraLabel: UILabel = { [unowned self] in
        let label = UILabel()
        label.font = FlexMediaPickerConfiguration.noCameraFont
        label.textColor = FlexMediaPickerConfiguration.noCameraColor
        label.text = FlexMediaPickerConfiguration.noCameraTitle
        label.sizeToFit()
        
        return label
        }()
    
    lazy var noCameraButton: UIButton = { [unowned self] in
        let button = UIButton(type: .system)
        let title = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.settingsFont, color: FlexMediaPickerConfiguration.settingsColor, text: FlexMediaPickerConfiguration.settingsTitle)
        
        button.setAttributedTitle(title, for: UIControlState())
        button.contentEdgeInsets = UIEdgeInsets(top: 5.0, left: 10.0, bottom: 5.0, right: 10.0)
        button.sizeToFit()
        button.layer.borderColor = FlexMediaPickerConfiguration.settingsColor.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(settingsButtonDidTap), for: .touchUpInside)
        
        return button
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
    var locationManager: LocationManager?
    var startOnFrontCamera: Bool = false
    
    var didGetPhoto: ((UIImage)->Void)?
    var didRecordVideo: ((URL)->Void)?
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
        if FlexMediaPickerConfiguration.recordLocation {
            locationManager = LocationManager()
        }
        
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
            url in
            self.didRecordVideo?(url)
        }
        
        self.footerSize = FlexMediaPickerConfiguration.footerHeight
        self.footerText = " "
        if let ccp = self.footer as? CameraMediaControlPanel {
            ccp.setupMenu(in: self)
            
            ccp.takePhotoActionHandler = {
                self.takePicture { image in
                    if let img = image {
                        self.didGetPhoto?(img)
                    }
                    
                    // TODO: do some effects when making a photo
                }
            }
            ccp.recVideoActionHandler = {
                if self.videoCamRecording {
                    self.videoCamRecording = false
                    self.stopVideoRecording()
                }
                else {
                    self.videoCamRecording = true
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
        previewLayer?.connection.videoOrientation = Helper.videoOrientation() // .portrait
        locationManager?.startUpdatingLocation()
    }

    public func closeView() {
        locationManager?.stopUpdatingLocation()
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
        
        let centerX = bb.width / 2
        
        noCameraLabel.center = CGPoint(x: centerX,
                                       y: bb.height / 2 - 80)
        
        noCameraButton.center = CGPoint(x: centerX,
                                        y: noCameraLabel.frame.maxY + 20)
        
        blurView.frame = bb
        containerView.frame = bb
        capturedImageView.frame = bb
        self.previewLayer?.frame = bb
        
        previewLayer?.connection.videoOrientation = Helper.videoOrientation()

    }
    
    // MARK: - Actions
    
    func settingsButtonDidTap() {
        DispatchQueue.main.async {
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(settingsURL)
            }
        }
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
    
    private func takePicture(_ completion: @escaping (UIImage?) -> Void) {
        guard let previewLayer = previewLayer else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.capturedImageView.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.capturedImageView.alpha = 0
            })
        })
        
        cameraMan.takePhoto(previewLayer, location: locationManager?.latestLocation) { image in
            completion(image)
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
    
    func showNoCamera(_ show: Bool) {
        [noCameraButton, noCameraLabel].forEach {
            show ? self.addSubview($0) : $0.removeFromSuperview()
        }
    }
    
    // CameraManDelegate
    func cameraManNotAvailable(_ cameraMan: CameraMan) {
        showNoCamera(true)
        focusImageView.isHidden = true
        delegate?.cameraNotAvailable()
    }
    
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
