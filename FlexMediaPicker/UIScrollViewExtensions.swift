//
//  UIScrollviewExtensions.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 26.10.2017.
//  Copyright © 2017 Martin Jacob Rehder. All rights reserved.
//

import UIKit

class ScrollViewNotifications {
    static let ScrollViewBeginsZoom = "scrollview-begins-zoom"
    static let ScrollViewEndsZoom = "scrollview-ends-zoom"
}

extension UIScrollView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        let note = Notification(name: Notification.Name(rawValue: ScrollViewNotifications.ScrollViewBeginsZoom))
        NotificationCenter.default.post(note)
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        let note = Notification(name: Notification.Name(rawValue: ScrollViewNotifications.ScrollViewEndsZoom))
        NotificationCenter.default.post(note)
    }
}
