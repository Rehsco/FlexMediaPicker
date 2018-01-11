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
import StyledOverlay
import MJRFlexStyleComponents

open class AlertViewFactory {
    
    open class func confirmation(title: String, subTitle: String, buttonText: String, iconName: String, confirmationResult: @escaping ((Bool) -> Void)) {
        Helper.ensureOnAsyncMainThread {
            let image = (UIImage(named: iconName, in: Bundle(for: AlertViewFactory.self), compatibleWith: nil) ?? UIImage(named: iconName))?.tint(FlexMediaPickerConfiguration.alertIconColor)
            let thumbnailImage = image?.circularImage(size: image?.size)
            let appearance = self.getAlertViewAppearance()
            let alertView = StyledMenuPopover(frame: UIScreen.main.bounds, configuration: appearance)
            self.addStandardButton(alertView: alertView, text: buttonText, tapHandler: {
                alertView.hide()
                confirmationResult(true)
            })
            self.addStandardCancelButton(alertView: alertView) {
                confirmationResult(false)
            }
            let atitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.alertTitleFont, color: FlexMediaPickerConfiguration.alertTitleColor, text: title)
            let asubtitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.alertTextFont, color: FlexMediaPickerConfiguration.alertTitleColor, text: subTitle)
            alertView.show(title: atitle, subTitle: asubtitle, topLeftPoint: nil, icon: thumbnailImage)
        }
    }
    
    open class func showSettingsRequest(title: String, message: String) {
        Helper.ensureOnAsyncMainThread {
            let appearance = self.getAlertViewAppearance()
            let alertView = StyledMenuPopover(frame: UIScreen.main.bounds, configuration: appearance)
            self.addStandardButton(alertView: alertView, text: NSLocalizedString("Open Settings", comment: ""), tapHandler: {
                alertView.hide()
                if let url = URL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            let image = (UIImage(named: "CloseView_36pt", in: Bundle(for: AlertViewFactory.self), compatibleWith: nil) ?? UIImage(named: "CloseView_36pt"))?.tint(FlexMediaPickerConfiguration.alertIconColor)
            let thumbnailImage = image?.circularImage(size: image?.size)
            let atitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.alertTitleFont, color: FlexMediaPickerConfiguration.alertTitleColor, text: title)
            let asubtitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.alertTextFont, color: FlexMediaPickerConfiguration.alertTitleColor, text: message)
            alertView.show(title: atitle, subTitle: asubtitle, topLeftPoint: nil, icon: thumbnailImage)
        }
    }
    
    open class func showFailAlert(title: String, message: String, iconName: String, okHandler: (() -> Void)? = nil) {
        Helper.ensureOnAsyncMainThread {
            let image = (UIImage(named: iconName, in: Bundle(for: AlertViewFactory.self), compatibleWith: nil) ?? UIImage(named: iconName))?.tint(FlexMediaPickerConfiguration.alertIconColor)
            let thumbnailImage = image?.circularImage(size: image?.size)
            let appearance = self.getAlertViewAppearance()
            let alertView = StyledMenuPopover(frame: UIScreen.main.bounds, configuration: appearance)
            self.addStandardButton(alertView: alertView, text: NSLocalizedString("Ok", comment: ""), tapHandler: {
                alertView.hide()
                okHandler?()
            })
            let atitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.alertTitleFont, color: FlexMediaPickerConfiguration.alertTitleColor, text: title)
            let asubtitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.alertTextFont, color: FlexMediaPickerConfiguration.alertTitleColor, text: message)
            alertView.show(title: atitle, subTitle: asubtitle, topLeftPoint: nil, icon: thumbnailImage)
        }
    }
    
    open class func queryForItemName(title: String, subtitle: String, textPlaceholder: String, iconName: String, completionHandler: @escaping ((String, Bool) -> Void)) {
        if let image = (UIImage(named: iconName, in: Bundle(for: AlertViewFactory.self), compatibleWith: nil) ?? UIImage(named: iconName))?.tint(FlexMediaPickerConfiguration.alertIconColor) {
            AlertViewFactory.queryForItemName(title: title, subtitle: subtitle, textPlaceholder: textPlaceholder, image: image, completionHandler: completionHandler)
        }
        else {
            NSLog("You did not provide a correct name: \(iconName)")
        }
    }
    
    open class func queryForItemName(title: String, subtitle: String, textPlaceholder: String, image: UIImage, completionHandler: @escaping ((String, Bool) -> Void)) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(50)) {
            let thumbnailImage = image.circularImage(size: CGSize(width: 56, height: 56))
            let appearance = AlertViewFactory.getAlertViewAppearance()
            let alertView = StyledMenuPopover(frame: UIScreen.main.bounds, configuration: appearance)

            let imenu = FlexTextFieldCollectionItem(reference: "textInput", text: NSAttributedString(string: ""))
            imenu.placeholderText = NSAttributedString(string: NSLocalizedString("Name", comment: ""))
            imenu.textFieldShouldReturn = {
                _ in
                return true
            }
            imenu.textIsMutable = true
            alertView.addMenuItem(imenu)
            
            self.addStandardButton(alertView: alertView, text: NSLocalizedString("Done", comment: ""), tapHandler: {
                if let text = imenu.text?.string, text != "" {
                    completionHandler(text, true)
                }
                else {
                    completionHandler(textPlaceholder, true)
                }
            })
            addStandardCancelButton(alertView: alertView) {
                completionHandler("", false)
            }
            let atitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.alertTitleFont, color: FlexMediaPickerConfiguration.alertTitleColor, text: title)
            let asubtitle = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.alertTextFont, color: FlexMediaPickerConfiguration.alertTitleColor, text: subtitle)
            alertView.show(title: atitle, subTitle: asubtitle, topLeftPoint: nil, icon: thumbnailImage)
        }
    }
    
    // MARK: - Buttons
    
    open class func addStandardButton(alertView: StyledMenuPopover, text: String, tapHandler: (() -> Void)? = nil) {
        let abt = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.alertButtonFont, color: FlexMediaPickerConfiguration.alertButtonTextColor, text: text)
        let button = FlexBaseCollectionItem(reference: UUID().uuidString, text: abt)
        button.itemSelectionActionHandler = {
            if tapHandler != nil {
                tapHandler?()
            }
            alertView.hide()
        }
        alertView.addMenuItem(button)
    }

    open class func addStandardCancelButton(alertView: StyledMenuPopover, tapHandler: (() -> Void)? = nil) {
        let abt = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.alertButtonFont, color: FlexMediaPickerConfiguration.alertButtonTextColor, text: "Cancel")
        let closeButton = FlexBaseCollectionItem(reference: UUID().uuidString, text: abt)
        closeButton.itemSelectionActionHandler = {
            if tapHandler != nil {
                tapHandler?()
            }
            alertView.hide()
        }
    }
    
    // MARK: - Styling
    
    open class func getAlertViewAppearance() -> StyledMenuPopoverConfiguration {
        let configuration = StyledMenuPopoverConfiguration()
        configuration.styleColor = FlexMediaPickerConfiguration.alertStyleColor
        configuration.closeButtonEnabled = true
        configuration.menuItemSize = CGSize(width: 220, height: 32)
        configuration.displayType = .normal
        configuration.showTitleInHeader = false
        configuration.menuItemStyleColor = FlexMediaPickerConfiguration.alertButtonColor
        configuration.closeButtonStyleColor = FlexMediaPickerConfiguration.alertButtonColor
        configuration.headerIconBackgroundColor = FlexMediaPickerConfiguration.alertSecondaryColor
        configuration.headerIconSize = CGSize(width: 64, height: 64)
        configuration.headerIconBorderColor = FlexMediaPickerConfiguration.alertStyleColor
        configuration.headerIconBorderWidth = 3.5
        configuration.headerStyleColor = .clear
        configuration.closeButtonText = Helper.applyFontAndColorToString(FlexMediaPickerConfiguration.alertButtonFont, color: FlexMediaPickerConfiguration.alertButtonTextColor, text: "Close")
        return configuration
    }
}
