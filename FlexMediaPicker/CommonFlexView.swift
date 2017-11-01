//
//  CommonFlexView.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 30.10.2017.
//  Copyright © 2017 Martin Jacob Rehder. All rights reserved.
//

import UIKit
import MJRFlexStyleComponents

open class CommonFlexView: FlexView {
    private var closeViewMenu: CommonIconViewMenu?
    var rightViewMenu: CommonIconViewMenu?
    
    func createBackOrCloseLeftMenu(closeHandler: @escaping ()->Void) {
        self.closeViewMenu = CommonIconViewMenu(size: CGSize(width: 50, height: 36), hPos: .left, vPos: .header, menuIconSize: 24)
        self.closeViewMenu?.createCloseIconMenuItem()
        self.closeViewMenu?.menuSelectionHandler = {
            type in
            if type == .close {
                closeHandler()
            }
        }
        self.addMenu(self.closeViewMenu!)
    }
    
    func hideViewElements(hide: Bool = false) {
        self.closeViewMenu?.viewMenu?.showHide(hide: hide)
    }
}
