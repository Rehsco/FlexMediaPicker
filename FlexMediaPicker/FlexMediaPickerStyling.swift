//
//  FlexMediaPickerStyling.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 07.11.2017.
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
import MJRFlexStyleComponents
import StyledOverlay

open class FlexMediaPickerStyling {

    class func applyStyling() {
        let ccvcApp = FlexBaseCollectionViewCell.appearance(whenContainedInInstancesOf: [ImagesCollectionView.self])
        ccvcApp.styleColor = .clear
        
        let stccApp = FlexPrimaryLabel.appearance(whenContainedInInstancesOf: [FlexFooterView.self, ImageMediaCollectionView.self])
        stccApp.labelTextAlignment = .center

        let stcc2App = FlexPrimaryLabel.appearance(whenContainedInInstancesOf: [FlexFooterView.self, SelectedAssetsCollectionView.self])
        stcc2App.labelTextAlignment = .left

        let sstccApp = FlexSecondaryLabel.appearance(whenContainedInInstancesOf: [FlexFooterView.self, ImagesCollectionView.self])
        sstccApp.labelTextAlignment = .right
        sstccApp.labelRightOffset = 5

        let ccApp = ImagesCollectionCell.appearance()
        ccApp.imageViewStyle = FlexShapeStyle(style: .roundedFixed(cornerRadius: 5))
        ccApp.selectedStyleColor = FlexMediaPickerConfiguration.selectedItemColor
        
        let cellApp = FlexCellView.appearance(whenContainedInInstancesOf: [ImagesCollectionView.self])
        cellApp.style = FlexShapeStyle(style: .roundedFixed(cornerRadius: 5))
        
        let footerApp = MainMediaControlPanel.appearance(whenContainedInInstancesOf: [ImagesCollectionView.self])
        footerApp.styleColor = FlexMediaPickerConfiguration.footerPanelColor
        
        let cfooterApp = CameraMediaControlPanel.appearance(whenContainedInInstancesOf: [CameraView.self])
        cfooterApp.styleColor = FlexMediaPickerConfiguration.footerPanelColor
        
        BusyViewFactory.topLabelFont = FlexMediaPickerConfiguration.upperProgressLabelFont
        BusyViewFactory.bottomLabelFont = FlexMediaPickerConfiguration.lowerProgressLabelFont
        BusyViewFactory.topLabelTextColor = FlexMediaPickerConfiguration.upperProgressLabelTextColor
        BusyViewFactory.bottomLabelTextColor = FlexMediaPickerConfiguration.lowerProgressLabelTextColor
    }
}
