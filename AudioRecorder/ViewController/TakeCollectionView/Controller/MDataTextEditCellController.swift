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
    
    var takeVC: TakeVC?
    
    // id of metadata item
    var id: String?
    
    var originalValue: String = ""
    
    // closure to send value to parent view (value, id)
    var updateValue: ((String, String) -> ())?
    
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
//        let screenWidth = UIScreen.main.bounds.size.width
//        widthConstraint.constant = screenWidth //- (2 * 8)
        
        //self.backgroundColor = Colors.Base.background.toUIColor()
        
        valueTextView.delegate = self
        
        
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        
        layoutAttributes.bounds.size.width = maxWidth!
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        return layoutAttributes
    }
    
    
    // MARK: TextView Delegate
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        print("textViewShouldReturn: \(valueTextView.text!)")
        
        // send indexPath to TakeVC
        let cv = self.superview as! UICollectionView
        let idx = cv.indexPath(for: self)
        takeVC?.selectedItemWithTextField = idx
        
        return true
    }
    
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        
        if valueTextView.text != originalValue {
            updateValue!(valueTextView.text!, id!)
        }
        return true
    }
}
