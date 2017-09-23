//
//  ViewController.swift
//  FlexMediaPickerExample
//
//  Created by Martin Rehder on 25.08.2017.
//  Copyright © 2017 Martin Jacob Rehder. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func pickImageSelected(_ sender: Any) {
        let vc = FlexMediaPickerViewController()
        
        self.present(vc, animated: true)
    }

}

