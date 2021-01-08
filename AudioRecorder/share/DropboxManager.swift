//
//  DropboxManager.swift
//  AudioRecorder
//
//  Created by Wolf on 30.11.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import SwiftyDropbox
import UIKit

class DropboxManager {
    
    static var sharedInstance = DropboxManager()
    
    /// Reference after programmatic auth flow
    var client = DropboxClientsManager.authorizedClient
    
    var takesInDropbox = [String]()
    
    func upload(path: URL) {
        
    }
    
    init() {
        //listFiles()
    }
    
    /// Find all folders with takes and add to takesInDropbox.
    /// Each takes should be in a folder
    func listFiles( closure: @escaping (Bool) -> Void ) {
        var fileNames = [String]()
        client?.files.listFolder(path: "").response(completionHandler: { response, error in
            if let result = response {
                //print (result)
                for file in result.entries {
                    //print(file.name)
                    
                    switch file {
                    case let fileMetadata as Files.FileMetadata:
                        print("FileMetadata: \(fileMetadata)")
                    
                    case let folderMetadata as Files.FolderMetadata:
                        print("Folder metadata: \(folderMetadata)")
                        fileNames.append(file.name)
                        
                    default:
                        print("Default")
                    }
//                    fileNames.append(file.name)
                }
                self.takesInDropbox = fileNames
                closure(true)
            }
        })
    }
    
    
    /// Start auth flow, old
    ///
    func auth(controller: UIViewController) {
        DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                      controller: controller,
                                                      openURL: { (url: URL) -> Void in
                                                        UIApplication.shared.canOpenURL(url)
                                                      })
    }
    
    /// Start auth flow, new version
    ///
    func authV2(controller: UIViewController) {
        let scopeRequest = ScopeRequest(scopeType: .user, scopes: ["account_info.read"], includeGrantedScopes: false)
        DropboxClientsManager.authorizeFromControllerV2(UIApplication.shared,
                                                        controller: controller,
                                                        loadingStatusDelegate: nil,
                                                        openURL: {(url: URL) -> Void in
                                                            UIApplication.shared.canOpenURL(url)
                                                        },
                                                        scopeRequest: scopeRequest)
    }
    
    
    // MARK: Upload to Drobbox
    
    /// Upload a take folder. Create metadata file if nessecary.
    ///
    /// - parameter folderURL: directory url
    ///
    func uploadTakeFolder(folderURL: URL, closure: @escaping (Bool) -> Void) {
        // make sure is directory and exists
        var isDirectory: ObjCBool = true
        let directoryExist = FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory)
        if directoryExist {
            let directoryName = folderURL.lastPathComponent
            
            do {
                let filesInFolder = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                var commitInfo = [URL: Files.CommitInfo]()
                for path in filesInFolder {
                    let pathInDropBox = "/" + directoryName + "/" + path.lastPathComponent
                    let commitInfoPath = SwiftyDropbox.Files.CommitInfo(path: pathInDropBox)
                    commitInfo[path] = commitInfoPath
                    
                    if path.pathExtension == "wav" {
                        // is there a metadata file?
                        let metadataFileUrl = path.deletingPathExtension().appendingPathExtension("json")
                        if !FileManager.default.fileExists(atPath: metadataFileUrl.path) {
                            let takeName = path.deletingPathExtension().lastPathComponent
                            if (Takes.sharedInstance.makeMetadataFile(takeName: takeName) == true) {
                                let metadataInfoPath = "/" + directoryName + "/" + takeName + ".json"
                                commitInfo[metadataFileUrl] = SwiftyDropbox.Files.CommitInfo(path: metadataInfoPath)                           }
                        }
                    }
                    
                    if (client != nil) {
                        client?.files.batchUploadFiles(fileUrlsToCommitInfo: commitInfo, responseBlock: { response, error, errorSet in
                            if let result = response {
                                for arg in result {
                                    print("key: \(arg.key.absoluteString), value: \(arg.value.description)")
                                }
                                closure(true)
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
    
}
