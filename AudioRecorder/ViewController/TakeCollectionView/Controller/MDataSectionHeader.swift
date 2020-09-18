//
//  MDataSectionHeader.swift
//  AudioRecorder
//
//  Created by Wolf on 06.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class MDataSectionHeader: UICollectionReusableView {

    @IBOutlet weak var headerName: UILabel!
    @IBOutlet weak var headerBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    @IBAction func headerBtnAction(_ sender: UIButton) {
        
    }
}
