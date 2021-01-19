//
//  DropboxVC.swift
//  AudioRecorder
//
//  Dropbox
//  List all recorded takes.
//  Mark all takes already saved to Dropbox App Directory.
//  Takes not in Dropbox are selectable and can be copied to Dropbox
//
//  Created by Wolf on 04.10.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit
import SwiftyDropbox

class DropboxVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var toolbarSaveBtn: UIBarButtonItem!
    
   // var takeCKRecordModel = TakeCKRecordModel()
    
    // all takes
    var takeNames = [String]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    //
    var takeNamesNew = [String]()
    var takesInDropbox = [String]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    /// Reference after programmatic auth flow
    var client = DropboxClientsManager.authorizedClient
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelection = true
        
        listFiles(fileType: "wav")
//        takeNames = Takes().getAllTakeNames(fileExtension: "wav", directory: nil, returnWithExtension: true)
        takeNames = Takes.sharedInstance.allTakeNames
        toolbarSaveBtn.isEnabled = false
    }
    
    /**
     Upload files at paths to Dropbox App directory.
     
     - parameters paths: URL's of files to upload
     */
    func upload(paths: [URL]) {
        client = DropboxClientsManager.authorizedClient
        
        var commitInfos = [URL: Files.CommitInfo]()
        for path in paths {
            let pathInDropBox = "/" + path.lastPathComponent
            let ci = SwiftyDropbox.Files.CommitInfo(path: pathInDropBox, mode: Files.WriteMode.overwrite)
            
            commitInfos[path] = ci
        }
        
        if (client != nil) {
          
            client?.files.batchUploadFiles(fileUrlsToCommitInfo: commitInfos, responseBlock: { response, error, errorSet in
                // Files.UploadSessionFinishBatchResultEntry
                if let result = response {
                    for arg in result {
                        print("key: \(arg.key.absoluteString), value: \(arg.value.description)")
                    }
                } else if let callError = error {
                    
                    switch callError as CallError {
                    case .accessError(let accessError, let userMessage, let errorSummary, let requestId):
                        print("AccessError[\(String(describing: requestId))]: \(String(describing: userMessage)) \(String(describing: errorSummary)) \(accessError)")
                    default:
                        print("Unknown Error: \(callError.description)")
                    }
                    for err in errorSet {
                        print("Error key: \(err.key.absoluteString), value: \(String(describing: err.value.description))")
                    }
                }
                
                // deselect and update description
                self.resetAfterUpload()
            })
            
            // uploadSessionStart version
            
//            let firstFileURL = paths.first
//            var firstFileSize: UInt64 = 0
//
//            do {
//                let fileDict = try FileManager.default.attributesOfItem(atPath: firstFileURL!.path)
//                firstFileSize = fileDict[FileAttributeKey.size] as! UInt64
//            } catch {
//                print("Error: \(error)")
//            }
//            client?.files.uploadSessionStart(close: false, input: paths.first!).response { [self] response, error in
//                if let result = response {
//                    let cursor = SwiftyDropbox.Files.UploadSessionCursor(sessionId: result.sessionId, offset: firstFileSize)
////                    client?.files.uploadSessionAppendV2(cursor: cursor, input: <#T##URL#>)
//                    client?.files.uploadSessionAppendV2(cursor: cursor, input: paths.last!)
//                }
//
//            }
        }
    }
    
    /**
     Upload directory
     Upload each file in directory
     
     */
    func upload(directoryURL: URL) {
        var isDirectory: ObjCBool = true
        let directoryExist = FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory)
        if directoryExist {
            let dirName = directoryURL.lastPathComponent
            //var filesInDir: [URL] = []
            
            do {
                let filesInDir = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                client = DropboxClientsManager.authorizedClient
                
                var commitInfos = [URL: Files.CommitInfo]()
                for path in filesInDir {
                    let pathInDropBox = "/" + dirName + "/" + path.lastPathComponent
                    let ci = SwiftyDropbox.Files.CommitInfo(path: pathInDropBox)
                    
                    commitInfos[path] = ci
                    
                    if (client != nil) {
                        client?.files.batchUploadFiles(fileUrlsToCommitInfo: commitInfos, responseBlock: { response, error, errorSet in
                            if let result = response {
                                for arg in result {
                                    print("key: \(arg.key.absoluteString), value: \(arg.value.description)")
                                }
                            } else if let callError = error {
                                switch callError as CallError {
                                case .accessError(let accessError, let userMessage, let errorSummary, let requestId):
                                    print("AccessError[\(String(describing: requestId))]: \(String(describing: userMessage)) \(String(describing: errorSummary)) \(accessError)")
                                default:
                                    print("Unknown Error: \(callError.description)")
                                }
                                for err in errorSet {
                                    print("Error key: \(err.key.absoluteString), value: \(String(describing: err.value.description))")
                                }
                            }
                        })
                    }
                }
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    
    func upload(path: String) {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0].appendingPathComponent(path)
        let exportFilePath = documentDirectory
        /// Reference after programmatic auth flow
        client = DropboxClientsManager.authorizedClient
//        let clientAccount = client?.account
//        let cloudDocs = client!.cloud_docs
        
        client?.files.upload(
            path: "/" + path,
            mode: .overwrite,
            autorename: false,
            clientModified: nil,
            mute: true,
            input: exportFilePath
        ) .response { response, error in
            if let response = response {
                print(response)
            } else if let error = error {
                print(error)
                switch error as CallError {
                case .routeError(let boxed, let userMessage, let errorSummary, let requestId):
                    print("RouteError[\(String(describing: requestId))")
                    switch boxed.unboxed as Files.UploadError {
                    case .path(let lookupError):
                        print("UploadError[\(String(describing: errorSummary))]: \(String(describing: userMessage)), \(String(describing: lookupError)) ")
                        
                    default:
                        print("Unkown")
                    }
                case .internalServerError(let code, let message, let requestId):
                    print("InternalServerError[\(String(describing: requestId))]: \(code): \(String(describing: message))")
                case .badInputError(let message, let requestId):
                    print("BadInputError[\(String(describing: requestId))]: \(String(describing: message))")
                case .rateLimitError(let rateLimitError, let userMessage, let errorSummary, let requestId):
                    print("RateLimitError[\(String(describing: requestId))]: \(String(describing: userMessage)) \(String(describing: errorSummary)) \(rateLimitError)")
                case .httpError(let code, let message, let requestId):
                    print("HTTPError[\(String(describing: requestId))]: \(String(describing: code)): \(String(describing: message))")
                case .authError(let authError, let userMessage, let errorSummary, let requestId):
                    print("AuthError[\(String(describing: requestId))]: \(String(describing: userMessage)) \(String(describing: errorSummary)) \(authError)")
                case .accessError(let accessError, let userMessage, let errorSummary, let requestId):
                    print("AccessError[\(String(describing: requestId))]: \(String(describing: userMessage)) \(String(describing: errorSummary)) \(accessError)")
                case .clientError(let error):
                    print("ClientError: \(String(describing: error))")
                }
            }
        }
        .progress { progressData in
            print(progressData)
        }
        
    }
    
    /**
     List files in Dropbox App directory
     
     - parameters fileType: fileType extension
     */
    func listFiles(fileType: String)  {
        var fileNames = [String]()
        
        client = DropboxClientsManager.authorizedClient
        
        client?.files.listFolder(path: "").response(completionHandler: { response, error in
            if let result = response {
                print(result)
                
                for file in result.entries {
                    print(file.name)
                    fileNames.append(file.name)
                }
                
                self.takesInDropbox = fileNames
            }
        })
    }
    
    
//    @IBAction func startBtn(_ sender: Any) {
//
//        let scopeRequest = ScopeRequest(scopeType: .user, scopes: ["account_info.read", "files.content.write"], includeGrantedScopes: false)
//        DropboxClientsManager.authorizeFromControllerV2(
//            UIApplication.shared,
//            controller: self,
//            loadingStatusDelegate: nil,
//            openURL: {
////                (url: URL) -> Void in UIApplication.shared.openURL(url)
//                (url: URL) -> Void in UIApplication.shared.open(url, options: [:], completionHandler: { result in
//                    print("authorizeCompletion: \(result)")
//                    print(url.absoluteString)
//                    //self.client = DropboxClient(accessToken: "7tt2r1ewvm0q9hm")
//                })
//            },
//            scopeRequest: scopeRequest
//        )
//    }
    
    @IBAction func toolbarSaveBtnAction(_ sender: UIBarButtonItem) {
        let selected = tableView.indexPathsForSelectedRows
        if selected != nil {
            let selectedRows = selected?.map { $0.row }
            var urlArray = [URL]()
            for row in 0..<selectedRows!.count {
                let takeName = takeNames[selectedRows![row]]
                if let dirURL = Takes().getDirectoryForFile(takeName: takeNames[selectedRows![row]], takeDirectory: AppConstants.takesFolder.rawValue) {
                     
                    //metadata json file
                    let metadataFileURL = dirURL.appendingPathComponent(takeNames[selectedRows![row]]).appendingPathExtension("json")
                    if FileManager.default.fileExists(atPath: metadataFileURL.path) {
                        // metadata file exists
                    } else {
                        // no metadata json file - create it
                        if (Takes().makeMetadataFile(takeName: takeName) == true ) {
                            
                        }
                    }
                    urlArray.append(dirURL)
                }
                
//                if let url = Takes().getUrlforFile(fileName: takeNames[selectedRows![row]]) {
//                    urlArray.append(url)
//
//                    // metadata json file
//                    let metadataFileURL = url.deletingPathExtension().appendingPathExtension("json")
//
//                    if FileManager.default.fileExists(atPath: metadataFileURL.path) {
//                        //takeRecord.metadataAsset = CKAsset(fileURL: metadataFileURL)
//                        urlArray.append(metadataFileURL)
//                    } else {
//                        // no metadata json file, create one
//                        let takeName = url.deletingPathExtension().lastPathComponent
//
//                        if (Takes().makeMetadataFile(takeName: takeName) == true) {
//                            // takeRecord.metadataAsset = CKAsset(fileURL: metadataFileURL)
//                            urlArray.append(metadataFileURL)
//                        }
//                    }
//
//                    // audioNote note?
//                    var takeNoteFileURL = url.deletingPathExtension().appendingPathComponent("notes")
//                    takeNoteFileURL.appendPathComponent(takeNames[selectedRows![row]], isDirectory: false)
//
//                    if FileManager.default.fileExists(atPath: takeNoteFileURL.path) {
//                        urlArray.append(takeNoteFileURL)
//                    }
//                }
                
            }
            
//            upload(paths: urlArray)
            upload(directoryURL: urlArray.first!)
        }
    }
    
    
    @IBAction func dropBoxAuth(_ sender: Any) {
        DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                      controller: self,
                                                      openURL: { (url: URL) -> Void in
                                                        UIApplication.shared.canOpenURL(url)
                                                      })
    }
    
    /**
     After successfully upload to Dropbox update tableView.
     Update takesInDropbox array.
     
     */
    func resetAfterUpload() {
        let selectedRows = tableView.indexPathsForSelectedRows
        if selectedRows != nil {
            for indexPath in selectedRows! {
                tableView.deselectRow(at: indexPath, animated: true)
                tableView.cellForRow(at: indexPath)?.accessoryView = .none
                takesInDropbox.append(takeNames[indexPath.row])
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        toolbarSaveBtn.isEnabled = false
    }
    
}
    
    //    func delete() {
//        let client = DropboxClientsManager.authorizedClient
//
//        client?.files.deleteV2(path: <#T##String#>)
//    }


extension DropboxVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return takeNames.count //+ takesInDropbox.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DropboxTableViewCellIdentifier", for: indexPath) as? ShareTableViewCell else {
            fatalError("The dequeued cell is not an instance of ShareTableViewCell")
        }
        
        cell.takeNameLabel.text = takeNames[indexPath.row]
        if takesInDropbox.contains(takeNames[indexPath.row]) {
            cell.takeStatusLabel.text = "in Dropbox"
        } else {
            cell.takeStatusLabel.text = "not in Dropbox"
        }
        
        cell.accessoryType = .none
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if !takesInDropbox.contains( takeNames[indexPath.row]) {
            return indexPath
        }
        //return indexPath
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("indexPathForSelectedRows: \(tableView.indexPathsForSelectedRows?.count ?? -1)")
        
        if let cell = tableView.cellForRow(at: indexPath) {
            if !takesInDropbox.contains(takeNames[indexPath.row]) {
                if cell.accessoryType == .none {
                    cell.accessoryType = .checkmark
                    
                } else {
                    cell.accessoryType = .none
                }
            }
        }
        
        if (tableView.indexPathsForSelectedRows != nil) {
            toolbarSaveBtn.isEnabled = true
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
         if (tableView.indexPathsForSelectedRows == nil) {
            toolbarSaveBtn.isEnabled = false
        }
    }
}
