//
//  MDataAudioCellController.swift
//  AudioRecorder
//
//  Created by Wolf on 29.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

class MDataAudioCellController: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var audioRecordBtn: UIButton!
    @IBOutlet weak var audioPlayBtn: UIButton!
    
    var maxWidth: CGFloat? = nil
    var audioURL: URL?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // note for take?
    }
    
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        
        layoutAttributes.bounds.size.width = maxWidth!
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        return layoutAttributes
    }
}
