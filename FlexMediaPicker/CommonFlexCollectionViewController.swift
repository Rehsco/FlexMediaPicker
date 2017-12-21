//
//  CommonFlexCollectionViewController.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 27.04.2017.
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

open class CommonFlexCollectionViewController: UIViewController {
    open var leftViewMenu: CommonIconViewMenu?
    open var rightViewMenu: CommonIconViewMenu?
    
    open var contentView: FlexCollectionView?
    open var mainSecRef: String?
    
    open var headerText: String?
    
    /// Set these to adjust margins on top of default view margins, such as safe area insets
    open var baseViewMargins: UIEdgeInsets = .zero
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.refreshView()
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            context.viewController(forKey: UITransitionContextViewControllerKey.from)
            self.whenTransition(to: size)
        }, completion: { context in
        })
    }
    
    open func whenTransition(to size: CGSize) {
    }
    
    open func setupView() {
        self.setupDefaultViewStyling()
    }
    
    open func refreshView() {
        self.contentView?.headerText = self.headerText
        if #available(iOS 11, *), let cv = self.contentView {
            cv.viewElementsInsets = UIEdgeInsetsMake(self.view.safeAreaInsets.top, 0, self.view.safeAreaInsets.bottom, 0)            
            cv.viewMargins = UIEdgeInsetsMake(self.view.safeAreaInsets.top + self.baseViewMargins.top,
                                              self.view.safeAreaInsets.left + self.baseViewMargins.left,
                                              self.view.safeAreaInsets.bottom + self.baseViewMargins.bottom,
                                              self.view.safeAreaInsets.right + self.baseViewMargins.right)
        }
    }
    
    open func populateContent() {
    }
    
    open func setupDefaultViewStyling() {
        self.automaticallyAdjustsScrollViewInsets = false
        // This also sets the status bar background color
        self.view.backgroundColor = FlexMediaPickerConfiguration.styleColor
    }
    
    // MARK: - Styling
    
    open func refreshCollectionCellSizes(width: CGFloat) {
        if let cv = self.contentView {
            for s in 0..<cv.numberOfSections(in: cv.itemCollectionView) {
                for i in 0..<cv.itemCollectionView.numberOfItems(inSection: s) {
                    let ip = IndexPath(item: i, section: s)
                    if let item = cv.getItemForIndexPath(ip) {
                        if let pcs = item.preferredCellSize {
                            item.preferredCellSize = CGSize(width: width, height: pcs.height)
                            cv.updateCellForItem(item.reference)
                        }
                    }
                }
            }
        }
    }

    open func applyCollectionViewDefaultStyling(collectionView: FlexCollectionView) {
        collectionView.defaultCellSize = CGSize(width: UIScreen.main.bounds.size.width - 20, height: 64)
        collectionView.header.caption.labelTextAlignment = .center
        collectionView.header.caption.labelFont = FlexMediaPickerConfiguration.headerFont
        collectionView.header.caption.labelTextColor = FlexMediaPickerConfiguration.headerTextColor
        collectionView.headerSize = FlexMediaPickerConfiguration.headerHeight
        collectionView.header.styleColor = FlexMediaPickerConfiguration.headerColor
        collectionView.styleColor = FlexMediaPickerConfiguration.styleColor
    }
    
    // MARK: - View logic
    
    open func closeView() {
        if self.isModal() {
            self.dismiss(animated: true)
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    open func isModal() -> Bool {
        if self.presentingViewController != nil {
            return true
        } else if self.navigationController?.presentingViewController?.presentedViewController == self.navigationController  {
            return true
        } else if self.tabBarController?.presentingViewController is UITabBarController {
            return true
        }
        return false
    }
    
    // MARK: - View Menu
    
    open func createIconMenu(width: CGFloat = 50, menuIconSize: CGFloat = 36) {
        self.rightViewMenu = CommonIconViewMenu(size: CGSize(width: width, height: 36), hPos: .right, vPos: .header, menuIconSize: menuIconSize)
    }
    
    open func createBackOrCloseLeftMenu(menuIconSize: CGFloat = 36) {
        self.leftViewMenu = CommonIconViewMenu(size: CGSize(width: 50, height: 36), hPos: .left, vPos: .header, menuIconSize: menuIconSize)
        if self.isModal() {
            self.leftViewMenu?.createCloseIconMenuItem()
            self.leftViewMenu?.menuSelectionHandler = {
                type in
                if type == .close {
                    self.dismiss(animated: true)
                }
            }
        }
        else {
            let swb = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeToGoBack(sender:)))
            self.view.addGestureRecognizer(swb)
            self.leftViewMenu?.createBackIconMenuItem()
            self.leftViewMenu?.menuSelectionHandler = {
                type in
                if type == .back {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        self.contentView?.addMenu(self.leftViewMenu!)
    }
    
    @objc open func swipeToGoBack(sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

}
