//
//  TakesTableViewCell.swift
//  AudioRecorder
//
//  Created by Wolf on 31.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class TakesTableViewCell: UITableViewCell {
    
    @IBOutlet weak var takeNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
