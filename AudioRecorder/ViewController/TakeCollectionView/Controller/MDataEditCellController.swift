//
//  MDataEditCellController.swift
//  AudioRecorder
//
//  Created by Wolf on 05.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class MDataEditCellController: UICollectionViewCell, UITextFieldDelegate {

    //@IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField!
    
    // closure to send value to parent view (value, id)
    var updateValue: ((String, String) -> ())?
    
    var originalValue: String = ""
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
        
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: leftAnchor),
            contentView.rightAnchor.constraint(equalTo: rightAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        //let screenWidth = UIScreen.main.bounds.width
        //widthConstraint.constant = screenWidth //- (2 * 8)
        
        valueTextField.delegate = self
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        
        descriptionLabel.preferredMaxLayoutWidth = maxWidth!
        layoutAttributes.bounds.size.width = maxWidth!
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        return layoutAttributes
    }
    
    // MARK: Keyboard change notifications
    
    @objc func adjustForKeyboardWillShow(notification: Notification) {
        print("MDataEditController: keyboardWillShow")
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let userInfo = notification.userInfo!
            let animationDuration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            
            UIView.animate(withDuration: animationDuration) {
                // self.layoutIfNeeded()
            }
        }
        
    }
    
    /**
     Keyboard hide notification - update value in item
     
    */
    @objc func adjustForKeyboardWillHide(notifiction: Notification) {
        print("keyboardWillHide")
        print(valueTextField.text!)
        
        //updateValue!(valueTextField.text!, id!)
    }
    
    
    // MARK: TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn: \(valueTextField.text!)")
        
//        let checkResult = Takes().checkFileName(newTakeName: valueTextField.text!, takeName: originalValue)
//
//        switch checkResult {
//        case "ok":
//            print("ok")
//
//        case "notUnique":
//            print("not Unique")
//
//        default:
//            print("default")
//        }
        
        updateValue!(valueTextField.text!, id!)
        
        textField.resignFirstResponder()
        return true
    }
}
