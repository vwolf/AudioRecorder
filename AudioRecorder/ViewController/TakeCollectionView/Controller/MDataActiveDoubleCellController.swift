//
//  MDataActiveDoubleCellController.swift
//  AudioRecorder
//
//  Created by Wolf on 05.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class MDataActiveDoubleCellController: UICollectionViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var subValueLabel: UILabel!
    
    @IBOutlet weak var valueBtn: UIButton!
    @IBOutlet weak var subValueBtn: UIButton!
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    var valueBtnAction: (() -> ())?
    
    var id: String?
    
    var maxWidth: CGFloat? = nil {
        didSet {
            guard let maxWidth = maxWidth else {
                return
            }
        }
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        
        let screenWidth = UIScreen.main.bounds.width
        widthConstraint.constant = screenWidth //- (2 * 8)
        
        backgroundColor = Colors.Base.background.toUIColor()
    }

    // target of button is added in CollectionViewController (TakeVC)
    @IBAction func valueBtnAction(_ sender: UIButton) {
        //valueBtnAction?()
    }
    
    @IBAction func subValueBtnAction(_ sender: UIButton) {
    }
    
}
