//
//  TakeCollectionViewFlowLayout.swift
//  AudioRecorder
//
//  Created by Wolf on 05.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

private let seperatorDecorationView = "seperator"

final class TakeCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    //var headerReferenceSize: CGSize = CGSize(width: 100, height: 100)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        register(SeperatorView.self, forDecorationViewOfKind: seperatorDecorationView)
        minimumLineSpacing = 1
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect) ?? []
        let lineWidth = self.minimumLineSpacing
        
        var decorationAttributes: [UICollectionViewLayoutAttributes] = []
        
        // skip first cell
        for layoutAttribute in layoutAttributes where layoutAttribute.indexPath.item > 0 {
            let seperatorAttribute = UICollectionViewLayoutAttributes(
                forDecorationViewOfKind: seperatorDecorationView, with: layoutAttribute.indexPath
            )
            
            let cellFrame = layoutAttribute.frame
            seperatorAttribute.frame = CGRect(x: cellFrame.origin.x,
                                              y: cellFrame.origin.y - lineWidth,
                                              width: cellFrame.size.width,
                                              height: lineWidth)
            seperatorAttribute.zIndex = Int.max
            decorationAttributes.append(seperatorAttribute)
        }
        
        return layoutAttributes + decorationAttributes
    }
    
    
}


private final class SeperatorView: UICollectionReusableView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = Colors.Base.background_main.toUIColor()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        self.frame = layoutAttributes.frame
    }
}
