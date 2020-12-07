//
//  SettingsTableBoolCell.swift
//  AudioRecorder
//
//  Created by Wolf on 30.11.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class SettingsTableBoolCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var stateSwitch: UISwitch!
    
    var switchState: Bool = false {
        didSet {
            stateSwitch.setOn(switchState, animated: true)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //stateSwitch.setOn(true, animated: false)
    }

//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
    
    @IBAction func stateSwitchAction(_ sender: UISwitch) {
        print("switch state!")
    }
}
