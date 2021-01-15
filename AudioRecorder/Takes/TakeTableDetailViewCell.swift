//
//  TakeTableDetailViewCell.swift
//  AudioRecorder
//
//  Created by Wolf on 25.11.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

/// TableViewCell for a Take. Button events are handled by TakesTableCellDelegate
///
class TakesTableDetailViewCell: UITableViewCell {
    
    
    @IBOutlet weak var takeNameLabel: UILabel!
    @IBOutlet weak var takeDetailsLabel: UILabel!
    
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var cloudBtn: UIButton!
    @IBOutlet weak var trashBtn: UIButton!
    @IBOutlet weak var metadataBtn: UIButton!
    
    var cellIndexPath: IndexPath?
    var tableIdx: Int = -1
    var sectionIdx: Int = -1
    
    var delegate: TakesTableCellDelegate?
    
    var take = Take() {
        didSet {
            takeName = take.takeName!
            loadTake(takeName: takeName)
        }
    }
    
    var takeName: String = "" {
        didSet {
            takeNameLabel.text = takeName
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
        if cellIndexPath != nil {
            delegate?.playCellTake(cellIndex: cellIndexPath!)
        }
    }
    
    @IBAction func cloudBtnAction(_ sender: UIButton) {
        if cellIndexPath != nil {
            delegate?.shareCellTake(cellIndex: cellIndexPath!)
        }
    }
    
    @IBAction func trashBtnAction(_ sender: UIButton) {
        if cellIndexPath != nil {
            delegate?.deleteCellTake(cellIndex: cellIndexPath!)
        }
    }
    
    @IBAction func metadataBtnAction(_ sender: UIButton) {
        if cellIndexPath != nil {
            delegate?.loadCellMetadata(cellIndex: cellIndexPath!)
        }
    }
    
    
    func loadTake(takeName: String) {
        guard let takeMO = Takes().loadTakeRecord(takeName: takeName) else {
            return
        }
        let recordingDate = takeMO.recordedAt
        let recordingDateString = recordingDate?.toString(dateFormat: "dd.MM.YY' at ' HH:mm:ss")

        if takeMO.length > 0 {
            takeDetailsLabel.text = "Recorded: \(recordingDateString ?? "?"), length: \(String(format: "%.2f", takeMO.length))"
        } else {
            takeDetailsLabel.text = "This is an empty take!"
            takeDetailsLabel.textColor = UIColor.red
        }
    
        /// Case: recording with no imput source then length == 0
        /// No playing, icloud or metadata
        if takeMO.length == 0 {
            playBtn.isEnabled = false
            cloudBtn.isEnabled = false
            metadataBtn.isEnabled = false
//            metadataBtn.alpha = 0.5
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
    
    /// Load all metadata for take, then trigger segue to 'TakeVC'
    ///
    /// - parameter row:  row index
    /// - parameter cell: selected table cell
    ///
//    func loadMetadata(row: Int, cell: UITableViewCell?) {
//
//        if cellIndexPath != nil {
//            delegate?.loadMetadata(cellIndexPath: cellIndexPath!)
//        }
//    }
}
