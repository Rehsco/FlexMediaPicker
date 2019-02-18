//
//  ViewController.swift
//  FlexMediaPickerExample
//
//  Created by Martin Rehder on 25.08.2017.
//  Copyright © 2017 Martin Jacob Rehder. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBAction func pickImageSelected(_ sender: Any) {
        FlexMediaPickerViewController.deleteAllMedia()
        
        FlexMediaPickerConfiguration.allowVideoSelection = false
        FlexMediaPickerConfiguration.allowImageFromVideoSelection = false

        
        let vc = FlexMediaPickerViewController()
        vc.mediaAcceptedHandler = {
            acceptedMedia in
            NSLog("\(acceptedMedia.count) media returned.")
            vc.dismiss(animated: true, completion: nil)
        }
        self.present(vc, animated: true)
    }
    
    @IBAction func pickImageOrVideoSelected(_ sender: Any) {
        FlexMediaPickerViewController.deleteAllMedia()

        FlexMediaPickerConfiguration.allowVideoSelection = true
        FlexMediaPickerConfiguration.allowImageFromVideoSelection = true

        let vc = FlexMediaPickerViewController()
        vc.mediaAcceptedHandler = {
            acceptedMedia in
            NSLog("\(acceptedMedia.count) media returned.")
            vc.dismiss(animated: true, completion: nil)
        }
        self.present(vc, animated: true)
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

