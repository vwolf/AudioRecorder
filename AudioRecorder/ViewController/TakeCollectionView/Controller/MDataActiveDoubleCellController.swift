//
//  MDataActiveDoubleCellController.swift
//  AudioRecorder
//
//  Created by Wolf on 05.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class MDataActiveDoubleCellController: UICollectionViewCell {

    //@IBOutlet weak var contentView: UIView!
    @IBOutlet weak var ctView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var subValueLabel: UILabel!
    
    @IBOutlet weak var valueBtn: UIButton!
    @IBOutlet weak var subValueBtn: UIButton!
    
    //@IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    var valueBtnAction: (() -> ())?
    
    var id: String?
    
    var maxWidth: CGFloat? = nil 

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: leftAnchor),
            contentView.rightAnchor.constraint(equalTo: rightAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
//        let screenWidth = UIScreen.main.bounds.width
//        widthConstraint.constant = screenWidth //- (2 * 8)
        
       // backgroundColor = Colors.Base.background.toUIColor()
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    
        descriptionLabel.preferredMaxLayoutWidth = maxWidth!
        self.frame.size.width = maxWidth!
        print("MDataActiveDoubleCellController.layoutFittingCompressedSize.height: \(systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)")
        print("MDataActiveDoubleCellController.layoutFittingExpandedSize.height: \(systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height)")
        
        layoutAttributes.bounds.size.width = maxWidth!
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        setNeedsLayout()
        layoutIfNeeded()
        return layoutAttributes
    }
    
    // target of button is added in CollectionViewController (TakeVC)
    @IBAction func valueBtnAction(_ sender: UIButton) {
        //valueBtnAction?()
    }
    
    @IBAction func subValueBtnAction(_ sender: UIButton) {
    }
    
}
