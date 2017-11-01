//
//  ViewController.swift
//  FlexMediaPickerExample
//
//  Created by Martin Rehder on 25.08.2017.
//  Copyright © 2017 Martin Jacob Rehder. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var cropView: ImageCropView?
    
    @IBAction func pickImageSelected(_ sender: Any) {
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
        let svf = CGRect(x: 0, y: 0, width: 250, height: 300)
        let sb = UIScreen.main.bounds
        self.cropView = ImageCropView(frame: CGRect(x: (sb.width - svf.width) * 0.5, y: (sb.height - svf.height) * 0.5, width: svf.width, height: svf.height), image: UIImage(named: "demoImage")!)
        self.view.addSubview(self.cropView!)
    }
}

