//
//  IndicatorViewController.swift
//  AudioRecorder
//
//  Created by Wolf on 27.12.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

class IndicatorViewController: UIViewController {
    
    var spinner = UIActivityIndicatorView(style: .whiteLarge)
    
    override func viewDidLoad() {
        view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}
