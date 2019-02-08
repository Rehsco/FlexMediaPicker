//
//  LocationMapView.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 11.12.2016.
/*
 * Copyright 2016-present Martin Jacob Rehder.
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
import MapKit

class LocationMapView: MKMapView {
    private var singleLocation: CLLocation?
    private var singleLocationTag: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.showsUserLocation = false
        self.userTrackingMode = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setSingleLocation(_ location: CLLocation?, tag: String?) {
        self.singleLocation = location
        self.singleLocationTag = tag
    }
    
    func setMapAnnotations() {
        self.removeAllAnnotations()
        
        if let location = self.singleLocation {
            let annotation = self.addLocationToMap(location, annotationTitle: self.singleLocationTag ?? "Location")
            let region = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: 1250.0, longitudinalMeters: 1250.0)
            let mRect = self.getMKMapRectForCoordinateRegion(region)
            self.setVisibleMapRect(mRect, animated: true)
            
            self.selectAnnotation(annotation, animated: false)
        }
    }
    
    private func addLocationToMap(_ location: CLLocation, annotationTitle: String = "Location") -> MKPointAnnotation {
        let coords = location.coordinate
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coords
        annotation.title = annotationTitle
        
        self.addAnnotation(annotation)
        return annotation
    }
    
    func removeAllAnnotations() {
        let annos = self.annotations
        let pins = Array(annos)
        
        self.removeAnnotations(pins)
    }

    private func getMKMapRectForCoordinateRegion(_ region: MKCoordinateRegion) -> MKMapRect {
        let a = MKMapPoint.init(CLLocationCoordinate2DMake(
            region.center.latitude + region.span.latitudeDelta / 2,
            region.center.longitude - region.span.longitudeDelta / 2))
        let b = MKMapPoint.init(CLLocationCoordinate2DMake(
            region.center.latitude - region.span.latitudeDelta / 2,
            region.center.longitude + region.span.longitudeDelta / 2))
        return MKMapRect.init(x: min(a.x,b.x), y: min(a.y,b.y), width: abs(a.x-b.x), height: abs(a.y-b.y))
    }
}
