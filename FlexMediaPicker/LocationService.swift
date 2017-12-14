//
//  LocationService.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 17.02.2017.
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

import CoreLocation
import UIKit
import MapKit

let locationService = LocationService()

open class LocationService: NSObject, CLLocationManagerDelegate  {
    let manager = CLLocationManager()
    private(set) var currentLongitude: String?
    private(set) var currentLatitude: String?
    private(set) var currentLocation: CLLocation?
    
    public func startLocationMessagingUse() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    class func isCurrentlyAuthorized() -> Bool {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        case .notDetermined, .restricted, .denied:
            return false
        }
    }
    
    public func checkAuthorization(_ fullAccessRequired: Bool) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            self.startLocationMessagingUse()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            self.startLocationMessagingUse()
        case .restricted, .denied:
            if fullAccessRequired {
                AlertViewFactory.showSettingsRequest(title: FlexMediaPickerConfiguration.requestPermissionTitle, message: FlexMediaPickerConfiguration.requestLocationPermissionMessage)
            }
        }
    }
    
    public func getCurrentLocationAsImage(completionHandler: @escaping (UIImage)->Void) {
        if let loc = locationService.currentLocation {
            let mapView = LocationMapView(frame: CGRect(origin: .zero , size: FlexMediaPickerConfiguration.locationImageSize))
            mapView.setSingleLocation(loc, tag: FlexMediaPickerConfiguration.currentLocationTagString)
            mapView.setMapAnnotations()
            self.takeSnapshot(mapView, withCallback: { (image, error) in
                if let e = error {
                    NSLog("Error creating location snapshot image: \(e.localizedDescription)")
                }
                else if let thumbnail = image {
                    completionHandler(thumbnail)
                }
                else {
                    NSLog("Location snapshort returned neither image nor an error!")
                }
            })
        }
    }
    
    private func takeSnapshot(_ mapView: MKMapView, withCallback: @escaping (UIImage?, NSError?) -> ()) {
        let options = MKMapSnapshotOptions()
        options.region = mapView.region
        options.size = mapView.frame.size
        options.scale = UIScreen.main.scale
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start(completionHandler: { snapshot, error in
            guard snapshot != nil else {
                withCallback(nil, error as NSError?)
                return
            }
            
            if let image = snapshot?.image {
                let finalImageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                
                UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
                
                image.draw(at:CGPoint.zero)
                
                let pin = MKPinAnnotationView()
                let pinImage = pin.image
                for annotation in mapView.annotations {
                    let point = snapshot?.point(for: annotation.coordinate)
                    if let po = point {
                        var p = po
                        if finalImageRect.contains(p) {
                            let pinCenterOffset = pin.centerOffset
                            p.x -= pin.bounds.size.width / 2.0
                            p.y -= pin.bounds.size.height / 2.0
                            p.x += pinCenterOffset.x
                            p.y += pinCenterOffset.y
                            pinImage?.draw(at: p)
                        }
                    }
                }
                let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                withCallback(finalImage, nil)
            }
        })
    }
    
    // MARK: - Location Manager Delegate
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
            let currentLocation = newLocation
            self.currentLocation = newLocation
            
            self.currentLongitude = NSString(format: "%.8f", currentLocation.coordinate.longitude) as String
            self.currentLatitude = NSString(format:"%.8f", currentLocation.coordinate.latitude) as String
        }
    }
}
