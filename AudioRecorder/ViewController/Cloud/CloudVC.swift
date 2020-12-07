//
//  CloudVC.swift
//  AudioRecorder
//
//  Created by Wolf on 25.11.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit
import AuthenticationServices

/// Copy or move take to external storage
/// iCloud, iDrive or Dropbox
/// Once the take is added to external storage, there is no return. 
/// Storage option only available if this take is not in storage
///
class CloudVC: UIViewController {

    // , ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding
//    @available(iOS 13.0, *)
//    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//        return self.view.window!
//    }
    
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var iCloudView: ICloudView!
    @IBOutlet weak var iDriveView: ICloudView!
    @IBOutlet weak var DropboxView: ICloudView!
    
    var take: Take = Take()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let accountStatus = TakeCKRecordModel.sharedInstance.accountStatus
        print(accountStatus.rawValue)
        
        if accountStatus == .available {
            print("available")
        } else {
            print("AccountStatus problem: \(accountStatus.rawValue)")
        }
        
        initICloudView()
        initIDriveView()
        initDropboxView()
//        iCloudView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(iCloudAction(_:))))
//        iDriveView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(iDriveAction(_:))))
//        DropboxView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dropBoxAction(_:))))
        
        navigationItem.title = take.takeName
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isMovingFromParent {
            
        }
    }
    
    
    private func findTakeIniCloud() -> Bool {
        if (TakeCKRecordModel.sharedInstance.getTakeCKRecord(takeName: take.takeName!) != nil) {
            return true
        }
        return false
    }
    
    private func findTakeIniDrive() -> Bool {
        return false
    }
    
    private func findTakeInDropbox() -> Bool {
        return false
    }
    
    @objc func iCloudAction(_ sender: UITapGestureRecognizer) {
        print("iCloudAction \(sender)")
        
        if TakeCKRecordModel.sharedInstance.accountStatus != .available {
            // apple id verification?
        } else {
            addTakeToICloud()
        }
    }
    
    
    func addTakeToICloud() {
        let takeName = take.takeName
        var urls: [URL] = []
        
        var sourceDirURL = CloudDataManager.DocumentsDirectory.localDocumentsURL.appendingPathComponent("takes")
        sourceDirURL.appendPathComponent(takeName!, isDirectory: true)
        
        do {
            let dirContents = try FileManager.default.contentsOfDirectory(at: sourceDirURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            urls.append(contentsOf: dirContents)
            
        } catch {
            print(error.localizedDescription)
        }
        
        // get wav file
        if let wavFile = urls.firstIndex(where: { $0.pathExtension == "wav"}) {
            //takeCKRecordModel.addTake(url: urls[wavFile])
            TakeCKRecordModel.sharedInstance.addTake(url: urls[wavFile])
        }
    }
    
//   @objc func handleAuthorizationAppleIDButtonPress() {
//        if #available(iOS 13.0, *) {
//            let appleIDProvider = ASAuthorizationAppleIDProvider()
//            let request = appleIDProvider.createRequest()
//            request.requestedScopes = [.email, .fullName]
//
//            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
//            authorizationController.delegate = self
//            authorizationController.presentationContextProvider = self
//            authorizationController.performRequests()
//        } else {
//            // Fallback on earlier versions
//        }
//    }
    
    
    @objc func iDriveAction(_ sender: UITapGestureRecognizer) {
        print("iDriveAction \(sender)")
        
        if CloudDataManager.sharedInstance.takeFolderToCloud(takeName: take.takeName!, takeDirectory: "takes") {
            // take moved (ubiqutios), remove from local takes
            Takes.sharedInstance.takeIsUbiquitous(takeName: take.takeName!)
        }
    }
    
    @objc func dropBoxAction(_ sender: UITapGestureRecognizer) {
        print("dropBoxAction \(sender)")
        
        DropboxManager.sharedInstance.listFiles()
    }
    
    private func initICloudView() {
        
        if take.iCloudState == .ICLOUD {
            iCloudView.label.text = CloudStrings.IniCloud.rawValue
            iCloudView.detailLabel.text = CloudStrings.ICloudDetails.rawValue
            
            //iCloudView.addBtn.setTitle("Replace", for: .normal)
            iCloudView.addBtn.setTitle("Copy To iCloud", for: .normal)
            iCloudView.addBtn.isEnabled = false
            iCloudView.addBtn.alpha = 0.4
        }
        
        if take.storageState == .LOCAL && take.iCloudState == .NONE {
            iCloudView.label.text = CloudStrings.NotIniCloud.rawValue
            iCloudView.detailLabel.text = CloudStrings.ICloudDetails.rawValue
            
            iCloudView.addBtn.setTitle("Copy To iCloud", for: .normal)
            iCloudView.addBtn.addTarget(self, action: #selector(iCloudAction(_:)), for: .touchUpInside)
        }

    }
    
    private func initIDriveView() {
        if take.iDriveState == .IDRIVE {
            iDriveView.label.text = CloudStrings.IniDrive.rawValue
            iDriveView.detailLabel.text = CloudStrings.IDriveDetails.rawValue
        
            iDriveView.addBtn.setTitle("Move to iDrive", for: .normal)
            iDriveView.addBtn.alpha = 0.4
        } else {
            iDriveView.label.text = CloudStrings.NotIniDrive.rawValue
            iDriveView.detailLabel.text = CloudStrings.IDriveDetails.rawValue
        
            iDriveView.addBtn.setTitle("Move to iDrive", for: .normal)
            iDriveView.addBtn.addTarget(self, action: #selector(iDriveAction(_:)), for: .touchUpInside)
        }
    }
    
    private func initDropboxView() {
        let dropboxActive = UserDefaults.standard.bool(forKey: "useDropbox")
        
        if !dropboxActive {
            DropboxView.label.text = CloudStrings.DropboxDontUse.rawValue
            DropboxView.detailLabel.text = CloudStrings.DropboxEnable.rawValue
            
            DropboxView.addBtn.alpha = 0.4
        } else {
            if take.storageState != .DROPBOX {
                DropboxView.label.text = CloudStrings.NotInDropbox.rawValue
                DropboxView.detailLabel.text = CloudStrings.DropboxDetails.rawValue
        
                DropboxView.addBtn.setTitle("Move to Dropbox", for: .normal)
                DropboxView.addBtn.addTarget(self, action: #selector(dropBoxAction(_:)), for: .touchUpInside)
            }
        }
    }
}


enum CloudStrings: String {
    case NotIniCloud = "Copy take to iCloud."
    case IniCloud = "Copy of take is in iCloud."
    case ICloudDetails = "This makes a copy in your iCloud. \nGet takes from iCloud using macOS app. \nMore..."
    
    case NotIniDrive = "Move take to iDrive."
    case IniDrive = "This take is already in iDrive"
    case IDriveDetails = "Moves take to your iDrive, folder takes. \nThis removes the take from your device."
    
    case NotInDropbox = "Copy take to Dropbox"
    case InDropbox = "There is already a copy of this take in your Dropbox"
    case DropboxDetails = "Copy take to your Dropbox"
    case DropboxDontUse = "Enable Dropbox"
    case DropboxEnable = "Enable Dropbox in Settings"
}
