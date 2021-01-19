//
//  AlertControllerExtension.swift
//  AudioRecorder
//
//  Created by Wolf on 18.01.21.
//  Copyright © 2021 Wolf. All rights reserved.
//

import UIKit

public enum TextValidationRule {
    case noRestriction
    case nonEmpty
    case unique
    
    public func isValid(_ input: String) -> Bool {
        switch self {
        case .noRestriction:
            return true
        case .nonEmpty:
            return !input.isEmpty
        case .unique:
            if input.isEmpty {return false}
            return !Takes.sharedInstance.fileWithNameExist(name: input)
        }
    }
}


extension UIAlertController {
    
    public enum TextInputResult {
        case cancel
        case ok(String)
    }
    
    public convenience init(title: String,
                            message: String? = nil,
                            cancelButtonTitle: String,
                            okButtonTitle: String,
                            validation validationRule: TextValidationRule = .noRestriction,
                            textFieldConfiguration: ((UITextField) -> Void)? = nil,
                            onCompletion: @escaping (TextInputResult) -> Void) {
        
        self.init(title: title, message: message, preferredStyle: .alert)
        
        /// Observes a UITextField for various events and reports them via callbacks.
        /// Sets itself as the text field's delegate and target-action target.
        class TextFieldObserver: NSObject, UITextFieldDelegate {
            let textFieldValueChanged: (UITextField) -> Void
            let textFieldShouldReturn: (UITextField) -> Bool
            
            var names: [String]?
            
            init(textField: UITextField, valueChanged: @escaping (UITextField) -> Void, shouldReturn: @escaping (UITextField) -> Bool) {
                self.textFieldValueChanged = valueChanged
                self.textFieldShouldReturn = shouldReturn
                super.init()
                textField.delegate = self
                textField.addTarget(self, action: #selector(textFieldValueChanged(sender:)), for: .editingChanged)
            }
            
            @objc func textFieldValueChanged(sender: UITextField) {
                textFieldValueChanged(sender)
            }
            
            // MARK: UITextFieldDelegate
            func textFieldShouldReturn(_ textField: UITextField) -> Bool {
                return textFieldShouldReturn(textField)
            }
        }
        
        var textFieldObserver: TextFieldObserver?
        
        // Every `UIAlertAction` handler must eventually call this
        func finish(result: TextInputResult) {
            // Capture the observer to keep it alive while the alert is on screen
            textFieldObserver = nil
            onCompletion(result)
        }
        
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: { _ in
            finish(result: .cancel)
        })
        
        let okAction = UIAlertAction(title: okButtonTitle, style: .default, handler: { [unowned self] _ in
            finish(result: .ok(self.textFields?.first?.text ?? ""))
        })
        
        addAction(cancelAction)
        addAction(okAction)
        preferredAction = okAction
        
        addTextField(configurationHandler: { textField in
            textFieldConfiguration?(textField)
            textFieldObserver = TextFieldObserver(textField: textField,
                                                  valueChanged: { textField in
                                                    okAction.isEnabled = validationRule.isValid(textField.text ?? "")
                                                  },
                                                  shouldReturn: { textField in
                                                    validationRule.isValid(textField.text ?? "")
                                                  })
        })
        // Start with a disabled OK button if necessary
        okAction.isEnabled = validationRule.isValid(textFields?.first?.text ?? "")
    }
}
