//
//  AlertViewFactory.swift
//  adapted from SafeCompanionPro
//
//  Created by Martin Rehder on 08.03.2017.
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
import SCLAlertView

open class AlertViewFactory {
    private static var alertView: SCLAlertView?
    
    open class func confirmation(title: String, subTitle: String, buttonText: String, iconName: String, confirmationResult: @escaping ((Bool) -> Void)) {
        let image = (UIImage(named: iconName, in: Bundle(for: AlertViewFactory.self), compatibleWith: nil) ?? UIImage(named: iconName))?.tint(FlexMediaPickerConfiguration.alertStyleColor)
        let thumbnailImage = image?.circularImage(size: CGSize(width: 52, height: 52))
        let appearance = self.sclAlertViewAppearance()
        let alertView = SCLAlertView(appearance: appearance)
        alertView.addButton(buttonText, backgroundColor: FlexMediaPickerConfiguration.alertStyleColor) {
            confirmationResult(true)
        }
        alertView.addButton(NSLocalizedString("Cancel", comment: ""), backgroundColor: FlexMediaPickerConfiguration.alertButtonColor) {
            confirmationResult(false)
            alertView.dismiss(animated: true)
        }
        _ = alertView.showCustom(title, subTitle: subTitle, color: FlexMediaPickerConfiguration.alertButtonColor, icon: thumbnailImage!)
    }
    
    open class func showSettingsRequest(title: String, message: String) {
        let appearance = self.sclAlertViewAppearance()
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Open Settings", backgroundColor: FlexMediaPickerConfiguration.alertButtonColor) {
            if let url = URL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        let _ = alert.showTitle(title, subTitle: message, style: SCLAlertViewStyle.error)
    }
    
    open class func showFailAlert(title: String, message: String, iconName: String, okHandler: (() -> Void)? = nil) {
        let image = (UIImage(named: iconName, in: Bundle(for: AlertViewFactory.self), compatibleWith: nil) ?? UIImage(named: iconName))?.tint(FlexMediaPickerConfiguration.alertStyleColor)
        let thumbnailImage = image?.circularImage(size: CGSize(width: 52, height: 52))
        let appearance = self.sclAlertViewAppearance()
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton(NSLocalizedString("Ok", comment: ""), backgroundColor: FlexMediaPickerConfiguration.alertButtonColor) {
            alertView?.dismiss(animated: true)
            okHandler?()
        }
        _ = alert.showCustom(title, subTitle: message, color: FlexMediaPickerConfiguration.alertButtonColor, icon: thumbnailImage!)
    }
    
    open class func queryForItemName(title: String, subtitle: String, textPlaceholder: String, iconName: String, completionHandler: @escaping ((String, Bool) -> Void)) {
        if let image = (UIImage(named: iconName, in: Bundle(for: AlertViewFactory.self), compatibleWith: nil) ?? UIImage(named: iconName))?.tint(FlexMediaPickerConfiguration.alertStyleColor) {
            AlertViewFactory.queryForItemName(title: title, subtitle: subtitle, textPlaceholder: textPlaceholder, image: image, completionHandler: completionHandler)
        }
        else {
            NSLog("You did not provide a correct name: \(iconName)")
        }
    }
    
    open class func queryForItemName(title: String, subtitle: String, textPlaceholder: String, image: UIImage, completionHandler: @escaping ((String, Bool) -> Void)) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(50)) {
            let thumbnailImage = image.circularImage(size: CGSize(width: 52, height: 52))
            let appearance = AlertViewFactory.sclAlertViewAppearance()
            let alertView = SCLAlertView(appearance: appearance)
            let inputTextField = alertView.addTextField(NSLocalizedString("Name", comment: ""))
            inputTextField.placeholder = textPlaceholder
            alertView.addButton(NSLocalizedString("Done", comment: ""), backgroundColor: FlexMediaPickerConfiguration.alertButtonColor) {
                if let text = inputTextField.text, text != "" {
                    completionHandler(text, true)
                }
                else {
                    completionHandler(textPlaceholder, true)
                }
            }
            addStandardCancelButton(alertView: alertView) {
                completionHandler("", false)
            }
            _ = alertView.showCustom(title, subTitle: subtitle, color: FlexMediaPickerConfiguration.alertButtonColor, icon: thumbnailImage!)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(50)) {
                inputTextField.becomeFirstResponder()
            }
        }
    }
    
    // MARK: - Buttons
    
    open class func addStandardCancelButton(alertView: SCLAlertView, tapHandler: (() -> Void)? = nil) {
        alertView.addButton(NSLocalizedString("Cancel", comment: ""), backgroundColor: FlexMediaPickerConfiguration.alertButtonColor) {
            if tapHandler != nil {
                tapHandler?()
            }
            else {
                alertView.dismiss(animated: true)
            }
        }
    }
    
    // MARK: - Styling
    
    open class func sclAlertViewAppearance() -> SCLAlertView.SCLAppearance {
        let appearance = SCLAlertView.SCLAppearance(
            kCircleHeight: 56.0,
            kCircleIconHeight: 20.0,
            kTitleFont: FlexMediaPickerConfiguration.alertTitleFont,
            kTextFont: FlexMediaPickerConfiguration.alertTextFont,
            kButtonFont: FlexMediaPickerConfiguration.alertButtonFont,
            showCloseButton: false,
//            circleBackgroundColor: FlexMediaPickerConfiguration.alertSecondaryStyleColor,
            contentViewColor: FlexMediaPickerConfiguration.alertSecondaryColor,
            contentViewBorderColor: FlexMediaPickerConfiguration.alertStyleColor,
            titleColor: FlexMediaPickerConfiguration.alertTitleColor
        )
        return appearance
    }
}
