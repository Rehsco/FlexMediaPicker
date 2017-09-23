//
//  BusyViewFactory.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 19.04.2017.
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
import StyledOverlay

open class BusyViewFactory {
    private static var overlayBusyView: StyledActionOverlay?
    private static var isBusy = false

    open class func showBusyOverlay(onView view: UIView? = nil, autoHideAfter: Int = 12, completionHandler: ((Void) -> Void)? = nil) {
        if self.isBusy {
            return // already busy
        }
        self.isBusy = true
        
        let dView: UIView
        if view == nil {
            dView = UIApplication.shared.keyWindow!
        }
        else {
            dView = view!
        }
        DispatchQueue.main.async {
            let infoWidth:CGFloat = 100
            let infoHeight:CGFloat = 100
            let origin = CGPoint(x: (dView.bounds.width - infoWidth) * 0.5, y: (dView.bounds.height - infoHeight) * 0.5)
            self.overlayBusyView = StyledActionOverlay(frame: CGRect(origin: origin, size: CGSize(width: infoWidth, height: infoHeight)))
            self.overlayBusyView?.alpha = 0
            self.overlayBusyView?.style = .roundedFixed(cornerRadius: 10)
            self.overlayBusyView?.styleColor = UIColor.black.withAlphaComponent(0.6)
            self.overlayBusyView?.actionType = .busyLoop
            dView.addSubview(self.overlayBusyView!)
            UIView.animate(withDuration: 0.3, animations: {
                self.overlayBusyView?.alpha = 1
            }, completion: {
                finished in
                completionHandler?()
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(autoHideAfter), execute: {
                    if self.overlayBusyView != nil {
                        self.hideBusyOverlay()
                    }
                })
            })
        }
    }
    
    open class func hideBusyOverlay(completionHandler: ((Void) -> Void)? = nil) {
        DispatchQueue.main.async {
            if self.overlayBusyView == nil {
                return
            }
            self.overlayBusyView?.alpha = 1
            UIView.animate(withDuration: 0.3, animations: {
                self.overlayBusyView?.alpha = 0
            }, completion: { finished in
                self.overlayBusyView?.removeFromSuperview()
                self.overlayBusyView = nil
                self.isBusy = false
                completionHandler?()
            })
        }
    }
}
