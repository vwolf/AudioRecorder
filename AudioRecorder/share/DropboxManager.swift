//
//  DropboxManager.swift
//  AudioRecorder
//
//  Created by Wolf on 30.11.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import SwiftyDropbox

class DropboxManager {
    
    static var sharedInstance = DropboxManager()
    
    var client = DropboxClientsManager.authorizedClient
    
    var takesInDropbox = [String]()
    
    func upload(path: URL) {
        
    }
    
    init() {
        listFiles()
    }
    
    
    func listFiles() {
        var fileNames = [String]()
        client?.files.listFolder(path: "").response(completionHandler: { response, error in
            if let result = response {
                print (result)
                
                for file in result.entries {
                    print(file.name)
                    fileNames.append(file.name)
                }
                
                self.takesInDropbox = fileNames
            }
        })
    }
}
