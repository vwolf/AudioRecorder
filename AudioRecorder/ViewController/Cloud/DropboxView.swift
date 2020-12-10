//
//  DropboxView.swift
//  AudioRecorder
//
//  Created by Wolf on 09.12.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

class DropboxView: UIView {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var addBtn: UIButton!
    
    @IBAction func addBtnAction(_ sender: UIButton) {
        print("iCloudView addBtnAction")
    }

    /// set to true during authorization flow
    var loggingIn = false
    
}
