//
//  MDataTextEditCellController.swift
//  AudioRecorder
//
//  Created by Wolf on 10.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class MDataTextEditCellController: UICollectionViewCell, UITextViewDelegate {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var valueTextView: UITextView!
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    // id of metadata item
    var id: String?
    
    // closure to send value to parent view (value, id)
    var updateValue: ((String, String) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        let screenWidth = UIScreen.main.bounds.size.width
        widthConstraint.constant = screenWidth //- (2 * 8)
        
        //self.backgroundColor = Colors.Base.background.toUIColor()
        
        valueTextView.delegate = self
    }
    
    
    // MARK: TextView Delegate
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    
}
