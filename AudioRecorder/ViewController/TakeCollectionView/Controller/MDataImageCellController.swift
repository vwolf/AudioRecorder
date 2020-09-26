//
//  MDataImageCellController.swift
//  AudioRecorder
//
//  Created by Wolf on 23.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit
import Photos

class MDataImageCellController: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var maxWidth: CGFloat? = nil
    
    var imageURL: NSURL?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: leftAnchor),
            contentView.rightAnchor.constraint(equalTo: rightAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        
        layoutAttributes.bounds.size.width = maxWidth!
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        return layoutAttributes
    }
    
    /**
     Fetch asset from url and display in imageView.image
     (retrieve original size use PHImageManagerMaximumSize as targetSize)
     
     - parameter urlString: URL of image
    */
    func setImage(urlString: String) {
        if let assetURL = URL(string: urlString) {
            let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [assetURL], options: nil)
            
            if let photo = fetchResult.firstObject{
                PHImageManager.default().requestImage(for: photo,
                                                      targetSize: CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height),
                                                      contentMode: .aspectFill,
                                                      options: nil) {
                                                        image, info in
                                                        self.imageView.image = image
                }
            }
        }
    }
}
