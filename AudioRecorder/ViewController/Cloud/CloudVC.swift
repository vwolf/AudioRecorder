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
    @IBOutlet weak var DropboxView: DropboxView!
    
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
        
        Takes.sharedInstance.connectDropboxTakes()
        
        initICloudView()
        initIDriveView()
        initDropboxView()
//        iCloudView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(iCloudAction(_:))))
//        iDriveView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(iDriveAction(_:))))
//        DropboxView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dropBoxAction(_:))))
        
        navigationItem.title = take.takeName
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if DropboxView.loggingIn {
            initDropboxView()
            DropboxView.loggingIn = false
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {}
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
    
    /// Event from iCloudView
    @objc func iCloudAction(_ sender: UITapGestureRecognizer) {
        print("iCloudAction \(sender)")
        
        if TakeCKRecordModel.sharedInstance.accountStatus != .available {
            // apple id verification?
        } else {
            switch take.storageState {
            case .NONE, .LOCAL:
                addTakeToICloud()
            case .ICLOUD:
                addTakeToLocal()
            
            default: print("Take storageState: \(take.storageState)")

            }
        }
    }
    
    /// Add selected take to app's iCloud container. This should happens in background..
    /// Completion closure notifiction to?
    ///
    /// Two possible scenarios:
    /// 1. Add take to iCloud and leave local copy as it.
    /// 2. Add take to iCloud and delete local copy (files and coredata record).
    ///
    func addTakeToICloud() {
        let takeName = take.takeName
//        var urls: [URL] = []
//
//        var sourceDirURL = CloudDataManager.DocumentsDirectory.localDocumentsURL.appendingPathComponent("takes")
//        sourceDirURL.appendPathComponent(takeName!, isDirectory: true)
//
//        do {
//            let dirContents = try FileManager.default.contentsOfDirectory(at: sourceDirURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
//            urls.append(contentsOf: dirContents)
//
//        } catch {
//            print(error.localizedDescription)
//        }
        let indicatorView = IndicatorViewController()
        self.addChild(indicatorView)
        indicatorView.view.frame = self.view.frame
        self.view.addSubview(indicatorView.view)
        indicatorView.didMove(toParent: self)
        
        TakeCKRecordModel.sharedInstance.addTake(take: take) { result, error in
            if error == nil {
                // take saved to iCloud, remove local data
                guard Takes.sharedInstance.deleteTake(take: self.take) else {
                    print("Could not delete take \(self.take.takeName ?? "unkown")")
                    return
                }
                
                guard ((self.take.coreDataController?.deleteTake(takeName: takeName!)) != nil) else {
                    return
                }
                
                // take data in app's documents directory and record in CoreData deleted.
                // Move take from takesLocal to takesICloud to updata TakesVC tableView
                if !Takes.sharedInstance.moveTakeToCloud(take: self.take) {
                    print("Could not move take \(self.take.takeName ?? "unknown?") to takesCloud")
                }
                
                self.take.iCloudState = .ICLOUD
                self.take.storageState = .ICLOUD
            
                Takes.sharedInstance.reloadFlag = true
                
                DispatchQueue.main.async {
                    self.initICloudView()
                    indicatorView.willMove(toParent: nil)
                    indicatorView.view.removeFromSuperview()
                    indicatorView.removeFromParent()
                }
                 
                

            } else {
                print(error?.localizedDescription ?? "Error addTakeToICloud")
                DispatchQueue.main.async {
                    indicatorView.willMove(toParent: nil)
                    indicatorView.view.removeFromSuperview()
                    indicatorView.removeFromParent()
                }

            }
        }
    }
    
    /// Move a take from iCloud container to app's document directory
    ///
    ///
    func addTakeToLocal() {
        print("addTakeToLocal: \(take.takeName!)")
        take.cloudTakeToLocal() { result in
            print(result)
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
    
    func addTakeToIDrive() {}
    
    @objc func iDriveAction(_ sender: UITapGestureRecognizer) {
        print("iDriveAction \(sender)")
        
        // always update metadata json file?
        take.writeJsonForTake() { metadataURL, error in
            if (error != nil) {
                // problem writing metadata file
                print(error!)
            } else {
                print(metadataURL)
                do {
                    try CloudDataManager.sharedInstance.takeFolderToDrive(takeName: take.takeName!, takeDirectory: "takes")
                    
                    // take moved (ubiqutios), remove from local takes
                    Takes.sharedInstance.takeIsUbiquitous(takeName: take.takeName!)
                    // delete coredata record
                    _ = self.take.coreDataController?.deleteTake(takeName: take.takeName!)
                } catch  {
                    print(error.localizedDescription)
                    print("Error code: \(error as NSError).code)")
                    
                    let ea = errorAlert(title: "Error", message: error.localizedDescription) { _ in
                        
                    }
                    
                    self.present(ea, animated: true)
                }
                
            }
        }
        
//
//        if take.metadataFile() == nil {
//            //take.writeJsonForTake(completion: <#T##(URL, Error?) -> Void#>)
//            _ = Takes.sharedInstance.makeMetadataFile(takeName: take.takeName!)
//        } else {
//            let metadataFileURL = take.metadataFile()
//            print("metadataFileURL: \(String(describing: metadataFileURL))")
//        }
//
//        if CloudDataManager.sharedInstance.takeFolderToCloud(takeName: take.takeName!, takeDirectory: "takes") {
//            // take moved (ubiqutios), remove from local takes
//            Takes.sharedInstance.takeIsUbiquitous(takeName: take.takeName!)
//        }
    }
    
    @objc func dropBoxAction(_ sender: UITapGestureRecognizer) {
        print("dropBoxAction \(sender)")
        // user auth with dropbox?
        if DropboxManager.sharedInstance.client == nil {
            auth()
        } else {
            let takeName = take.takeName
            if let dirURL = Takes.sharedInstance.getDirectoryForFile(takeName: takeName!, takeDirectory: AppConstants.takesFolder.rawValue) {
                DropboxManager.sharedInstance.uploadTakeFolder(folderURL: dirURL) { result in
                    if result {
                        self.take.dropboxState = .DROPBOX
                        self.initDropboxView()
                    }
                }
            }
        }
    }
    
    /// Activate Dropbox usage
    @objc func dropBoxActivation(_ sender: UITapGestureRecognizer) {
        DropboxView.loggingIn = true
        UserDefaults.standard.setValue(true, forKey: "useDropbox")
        if DropboxManager.sharedInstance.client == nil {
            auth()
        } else {
            initDropboxView()
        }
    }
    
    
    func auth() {
        // DropboxManager.sharedInstance.auth(controller: self)
        DropboxManager.sharedInstance.authV2(controller: self)
    }
    
    
    private func initICloudView() {
        
        iCloudView.label.text = CloudStrings.NotIniCloud.rawValue
        iCloudView.detailLabel.text = CloudStrings.ICloudDetails.rawValue
        iCloudView.addBtn.setTitle("Copy To iCloud", for: .normal)
        iCloudView.addBtn.isEnabled = false
        iCloudView.addBtn.alpha = 0.4
        
        iCloudView.addBtn.layer.cornerRadius = 4
//        if take.iCloudState == .ICLOUD {
//            iCloudView.label.text = CloudStrings.IniCloud.rawValue
//            iCloudView.detailLabel.text = CloudStrings.ICloudBackDetails.rawValue
//
//            //iCloudView.addBtn.setTitle("Replace", for: .normal)
//            iCloudView.addBtn.setTitle("Move to app", for: .normal)
//            iCloudView.addBtn.addTarget(self, action: #selector(iCloudAction(_:)), for: .touchUpInside)
//            //iCloudView.addBtn.isEnabled = false
//            //iCloudView.addBtn.alpha = 0.4
//        }
//
//        if take.storageState == .LOCAL && take.iCloudState == .NONE {
//            iCloudView.label.text = CloudStrings.NotIniCloud.rawValue
//            iCloudView.detailLabel.text = CloudStrings.ICloudDetails.rawValue
//
//            iCloudView.addBtn.setTitle("Copy To iCloud", for: .normal)
//            iCloudView.addBtn.addTarget(self, action: #selector(iCloudAction(_:)), for: .touchUpInside)
//        }

       
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
        
        iDriveView.addBtn.layer.cornerRadius = 4
        iDriveView.addBtn.layer.borderWidth = 1
        iDriveView.addBtn.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    /// Using Dropbox needs two steps: activation in Settings and authorization with Dropbox
    ///
    private func initDropboxView() {
        let dropboxActive = UserDefaults.standard.bool(forKey: "useDropbox")
        
        if !dropboxActive {
            // dropbox inactive in User Settings
            DropboxView.label.text = CloudStrings.DropboxDontUse.rawValue
            DropboxView.detailLabel.text = CloudStrings.DropboxEnable.rawValue
            
            //DropboxView.addBtn.alpha = 0.4
            DropboxView.addBtn.setTitle("Enable Dropbox", for: .normal)
            if DropboxView.addBtn.allTargets.count != 0 {
                for target in DropboxView.addBtn.allTargets {
                    DropboxView.addBtn.removeTarget(target, action: #selector(dropBoxAction(_:)), for: .touchUpInside)
                }
            }
            DropboxView.addBtn.addTarget(self, action: #selector(dropBoxActivation(_:)), for: .touchUpInside)
            
        } else  {
            if DropboxManager.sharedInstance.client == nil {
                // Usersettings dropbox usage active but no authorization with Dropbox
                DropboxView.label.text = CloudStrings.DropboxAuth.rawValue
                
                DropboxView.addBtn.setTitle("Login", for: .normal)
            } else if take.dropboxState != .DROPBOX {
                // take not yet in dropbox
                DropboxView.label.text = CloudStrings.NotInDropbox.rawValue
                DropboxView.detailLabel.text = CloudStrings.DropboxDetails.rawValue
        
                DropboxView.addBtn.setTitle("Move to Dropbox", for: .normal)
                DropboxView.addBtn.addTarget(self, action: #selector(dropBoxAction(_:)), for: .touchUpInside)
            } else {
                // take already in dropbox
                DropboxView.detailLabel.text = CloudStrings.InDropbox.rawValue
                
                DropboxView.addBtn.isEnabled = false
                DropboxView.addBtn.alpha = 0.4
            }
        }
        
        DropboxView.addBtn.layer.cornerRadius = 4
        DropboxView.addBtn.layer.borderWidth = 1
        DropboxView.addBtn.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    // MARK: - ERROR
    
    /// Error alert to confirmed by user
    ///
    /// - Parameters:
    ///   - title: dialog title
    ///   - message: dialog message
    ///   - completion:
    /// - Returns:
    func errorAlert(title: String, message: String, completion: @escaping (Bool) -> ()?) -> UIAlertController {
        let ok = UIAlertAction(title: "OK", style: .default) { _ in
            completion(true)
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(ok)

        return alertController
    }
}


enum CloudStrings: String {
    case NotIniCloud = "Copy take to iCloud."
    case IniCloud = "Copy of take is in iCloud."
    case ICloudDetails = "This makes a copy in your iCloud. \nGet takes from iCloud using macOS app. \nMore..."
    case ICloudBackDetails = "Remove take from iCloud and add to App."
    
    case NotIniDrive = "Move take to iDrive."
    case IniDrive = "This take is already in iDrive"
    case IDriveDetails = "Moves take to your iDrive, folder takes. \nThis removes the take from your device."
    
    case NotInDropbox = "Copy take to Dropbox"
    case InDropbox = "There is already a copy of this take in your Dropbox"
    case DropboxDetails = "Copy take to your Dropbox"
    case DropboxDontUse = "Enable Dropbox"
    case DropboxEnable = "Enable Dropbox in Settings"
    case DropboxAuth = "Login Dropbox"
}
