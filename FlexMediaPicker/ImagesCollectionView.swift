//
//  ImagesCollectionView.swift
//  FlexImagePicker
//
//  Created by Martin Rehder on 18.07.2017.
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
import FlexCollections
import FlexViews

open class ImagesCollectionView: FlexCollectionView {
    
    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
        if let fc = cell as? FlexBaseCollectionViewCell {
            fc.imageViewSize = self.thumbnailSize()
        }
        return cell
    }
    
    func thumbnailSize() -> CGSize {
        let us = FlexMediaPickerConfiguration.thumbnailSize
        let currentSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? us.height : us.height * 0.8
        return CGSize(width: currentSize, height: currentSize * 0.8)
    }
}

class ImagesCollectionItem: FlexBaseCollectionItem {
    var imageIndex: Int = 0
    var isGroup: Bool = false
    var itemMenu: CommonIconViewMenu? = nil
    var isFocused: Bool = false
}

class ImagesCollectionCell: FlexBaseCollectionViewCell {
    
    override func applySelectionStyles(_ fcv: FlexView) {
        super.applySelectionStyles(fcv)
        if let ici = self.item as? ImagesCollectionItem, let menu = ici.itemMenu {
            if ici.isFocused {
                if menu.viewMenu?.superview == nil {
                    fcv.addMenu(menu)
                }
            }
            else {
                fcv.removeMenu(menu)
                DispatchQueue.main.async {
                    fcv.setNeedsLayout()
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        if let ici = self.item as? ImagesCollectionItem, let menu = ici.itemMenu {
            self.flexContentView?.removeMenu(menu)
        }
    }
    
}
