//
//  MDataStaticCellController.swift
//  AudioRecorder
//
//  Created by Wolf on 04.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

/**
 CollectionViewCell to display static value
 
 */
class MDataStaticCellController: UICollectionViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var ValueLabel: UILabel!
   // @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    var maxWidth: CGFloat? = nil 

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        
        //        NSLayoutConstraint.activate([
        //            contentView.leftAnchor.constraint(equalTo: leftAnchor),
        //            contentView.rightAnchor.constraint(equalTo: rightAnchor),
        //            contentView.topAnchor.constraint(equalTo: topAnchor),
        //            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        //        ])
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
       // print("MDataStaticCellController.preferredLayoutAttributesFitting maxWidth: \(String(describing: maxWidth))")
        
        descriptionLabel.preferredMaxLayoutWidth = maxWidth!
        ValueLabel.frame.size.width = maxWidth!
        
        layoutAttributes.bounds.size.width = maxWidth!
        //print("layoutFittingCompressedSize.height: \(systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)")
        //print("layoutFittingExpandedSize.height: \(systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height)")
        
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        //layoutAttributes.bounds.size.width = systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).width
        //frame.size.width = maxWidth!
        
        setNeedsLayout()
        layoutIfNeeded()
        
        //super.preferredLayoutAttributesFitting(layoutAttributes)
        return layoutAttributes
    }

}
