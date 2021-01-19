//
//  ICloudView.swift
//  AudioRecorder
//
//  Created by Wolf on 26.11.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

class ICloudView: UIView {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var addBtn: UIButton!
    
    @IBAction func addBtnAction(_ sender: UIButton) {
        print("iCloudView addBtnAction")
    }
    
    
//    init() {
//        super.init()
//
//        //label.text = "new label text"
//
//        super.init(frame: self.bounds)
//
//    }
    
//
//    required init?(coder: NSCoder) {
//        //super.init(coder: coder)
//        fatalError("init(coder:) has not been implemented")
//    }
    
}
