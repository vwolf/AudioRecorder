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
    
    var takeVC: TakeVC?
    
    // closure to send value to parent view (value, id)
    var updateValue: ((String, String) -> ())?
    
    var originalValue: String = ""
    var id: String?
    
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
        
        //let screenWidth = UIScreen.main.bounds.width
        //widthConstraint.constant = screenWidth //- (2 * 8)
        
        valueTextField.delegate = self
        
        //let notifictationCenter = NotificationCenter.default
        //notifictationCenter.addObserver(self, selector: #selector(adjustForKeyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil )
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        
        //descriptionLabel.preferredMaxLayoutWidth = maxWidth!
        layoutAttributes.bounds.size.width = maxWidth!
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        return layoutAttributes
    }
    
    // MARK: Keyboard change notifications
    
//    @objc func adjustForKeyboardWillShow(notification: Notification) {
//        print("MDataEditController: keyboardWillShow")
//
//        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//            let userInfo = notification.userInfo!
//            let animationDuration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
//
//            UIView.animate(withDuration: animationDuration) {
//                // self.layoutIfNeeded()
//            }
//        }
//
//    }
    
    /**
     Keyboard hide notification - update value in item
     
    */
    @objc func adjustForKeyboardDidHide(notification: Notification) {
        print("keyboardDidHide")
        //print("notification.name: \(notification.name)")
        print(notification.userInfo!)
//        print(valueTextField.text!)
//
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            print(keyboardSize.size.height)
            if keyboardSize.size.height == 0.0 {
                //valueTextField.resignFirstResponder()
                //updateValue!(valueTextField.text!, id!)
            }
        }
        
        
    }
    
    
    // MARK: TextField Delegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // send indexPath to TakeVC
        let cv = self.superview as! UICollectionView
        let idx = cv.indexPath(for: self)
        takeVC?.selectedItemWithTextField = idx
        
        return true
    }
    
    
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
        
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("textFieldDidEndEditing")
        
        updateValue!(valueTextField.text!, id!)
        
        textField.resignFirstResponder()
    }
}
