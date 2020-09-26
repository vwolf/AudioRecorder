//
//  MetadataAddCellController.swift
//  AudioRecorder
//
//  Created by Wolf on 18.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

class MetadataAddCellController: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addBtn: UIButton!
    
    override func awakeFromNib() {
//        self.contentView.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            contentView.leftAnchor.constraint(equalTo: leftAnchor),
//            contentView.rightAnchor.constraint(equalTo: rightAnchor),
//            contentView.topAnchor.constraint(equalTo: topAnchor),
//            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
//        ])
    }
    @IBAction func addBtnAction(_ sender: UIButton) {
    }
}
