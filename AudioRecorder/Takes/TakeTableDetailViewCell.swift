//
//  TakeTableDetailViewCell.swift
//  AudioRecorder
//
//  Created by Wolf on 25.11.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class TakesTableDetailViewCell: UITableViewCell {
    
    
    @IBOutlet weak var takeNameLabel: UILabel!
    @IBOutlet weak var takeDetailsLabel: UILabel!
    
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var cloudBtn: UIButton!
    @IBOutlet weak var trashBtn: UIButton!
    @IBOutlet weak var metadataBtn: UIButton!
    
    
    var take = Take() {
        didSet {
            takeName = take.takeName!
//            takeNameLabel.text = take.takeName
            loadTake(takeName: takeName)
        }
    }
    
    var takeName: String = "" {
        didSet {
            takeNameLabel.text = takeName
            //loadTake(takeName: takeName)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func playBtnAction(_ sender: UIButton) {
        print("Cell playBtnAction")
    }
    
    @IBAction func cloudBtnAction(_ sender: UIButton) {
    }
    
    @IBAction func trashBtnAction(_ sender: UIButton) {
    }
    
    @IBAction func metadataBtnAction(_ sender: UIButton) {
    }
    
    func loadTake(takeName: String) {
        guard let takeMO = Takes().loadTake(takeName: takeName) else {
            return
        }
        let recordingDate = takeMO.recordedAt
        let recordingDateString = recordingDate?.toString(dateFormat: "dd.MM.YY' at' HH:mm:ss")

        takeDetailsLabel.text = "Recorded: \(recordingDateString ?? "?"), length: \(String(format: "%.2f", takeMO.length))"
    
        /// Case: recording with no imput source then length == 0
        /// No playing, icloud or metadata
        if takeMO.length == 0 {
            playBtn.isEnabled = false
            cloudBtn.isEnabled = false
            metadataBtn.isEnabled = false
            if #available(iOS 13.0, *) {
//                let systemImage = UIImage(systemName: "icloud.fill")
//                cloudBtn.setImage(systemImage, for: .normal)
                cloudBtn.tintColor = UIColor.darkGray
            } else {
                // Fallback on earlier versions
                cloudBtn.setImage(UIImage(named: "icloud"), for: .normal)
            }
        }
        
        //take = Take(withTakeMO: takeMO)
        
//        if let takeCKRecord = TakeCKRecordModel.sharedInstance.getTakeCKRecord(takeName: takeName) {
//
//        }
    }
}
