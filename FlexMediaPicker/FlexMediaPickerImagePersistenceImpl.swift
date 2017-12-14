//
//  FlexMediaPickerImagePersistenceImpl.swift
//  FlexMediaPicker
//
//  Created by Martin Rehder on 07.10.2017.
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
import ImagePersistence

open class FlexMediaPickerImagePersistenceImpl: ImagePersistence {
    var _imageCache = ImageCache(maxNumImages: 10, maxImageMemoryThreshold: 128)
    open override var imageCache: ImageCache {
        get {
            return self._imageCache
        }
        set {
            self._imageCache = newValue
        }
    }
    
    /// Set this closure for handling encryption of image data
    open var encryptImageHandler: ((Data)->Data?)?
    /// Set this closure for handling decryption of image data
    open var decryptImageHandler: ((Data)->Data?)?

    open override func encryptImage(_ data: Data) -> Data? {
        if let eh = self.encryptImageHandler {
            return eh(data)
        }
        return data
    }
    
    open override func decryptImage(_ data: Data) -> Data? {
        if let dh = self.decryptImageHandler {
            return dh(data)
        }
        return data
    }
}
