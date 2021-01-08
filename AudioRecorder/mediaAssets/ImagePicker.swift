//
//  ImagePicker.swift
//  AudioRecorder
//
//  Created by Wolf on 23.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

public protocol ImagePickerDelegate: class {
    func didSelect(image: UIImage)
    func didSelect(image: UIImage, referenceURL: NSURL, imageURL: URL)
}

		
open class ImagePicker : NSObject {
    
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?
    
    public init( presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()
        
        super.init()
        
        self.presentationController = presentationController
        self.delegate = delegate
        
        self.pickerController.delegate = self
        self.pickerController.allowsEditing = false
        //self.pickerController.mediaTypes = ["public.image"]
    }
    
    
    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }
        
        return UIAlertAction(title: title, style: .default) {
            [unowned self] _ in
            self.pickerController.sourceType = .photoLibrary
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }
    
    public func present(from sourceView:UIView) {
        let alertController = UIAlertController(title: "Choose", message: nil, preferredStyle: .actionSheet)
        
        if let action = self.action(for: .camera, title: "Take photo") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .savedPhotosAlbum, title: "Camera roll") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .photoLibrary, title: "Photo library") {
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        } else {
//            alertController.popoverPresentationController?.sourceView = sourceView
//            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
        }
        
        self.presentationController?.present(alertController, animated: true)
    }
    
    public func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)
        
        if (image != nil) {
            self.delegate?.didSelect(image: image!)
        }
    }
    
    public func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?, referenceURL: NSURL, imageURL: URL) {
        controller.dismiss(animated: true, completion: nil)
        self.delegate?.didSelect(image: image!, referenceURL: referenceURL, imageURL: imageURL)
    }
}


extension ImagePicker: UIImagePickerControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }
        
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return self.pickerController(picker, didSelect: nil)
        }
        
        if #available(iOS 11.0, *) {
            guard let referenceURL = info[UIImagePickerController.InfoKey.referenceURL] as? NSURL else {
                return self.pickerController(picker, didSelect: nil)
            }
            
            let mediaType = info[UIImagePickerController.InfoKey.mediaType]
            guard let imageURL = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
                return self.pickerController(picker, didSelect: nil)
            }
            print(imageURL.path)
            self.pickerController(picker, didSelect: image, referenceURL: referenceURL, imageURL: imageURL)
        } else {
            // Fallback on earlier versions
            guard let referenceURL = info[UIImagePickerController.InfoKey.referenceURL] as? NSURL else {
                return self.pickerController(picker, didSelect: nil)
            }
            
            let mediaType = info[UIImagePickerController.InfoKey.mediaType]
            
            guard let imageURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
                return self.pickerController(picker, didSelect: nil)
            }
            
            print(imageURL.path)
            self.pickerController(picker, didSelect: image, referenceURL: referenceURL, imageURL: imageURL)
        }
        
    }
}


extension ImagePicker: UINavigationControllerDelegate {
    
}

