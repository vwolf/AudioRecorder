//
//  UserSettings.swift
//  AudioRecorder
//
//  Created by Wolf on 05.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

/**
 User defined settings saved in CoreData (Usersettings)
 User defined settiings are:
 - takeName: preset for new recorded takes
 - style: color scheme (not implementet jet)
 - reccordingsetting: recording format
 - shareClient: Service to share data
 */
class UserSettings {
    
    /// get CoreDataController
    var coreDataController = (UIApplication.shared.delegate as! AppDelegate).coreDataController {
        didSet {
            fetchUserSettings()
        }
    }
    
    var userSettingsMO = [UserSettingsMO]()
    // dictionary for display of settings
    //var userSettings = [UserSetting]()
    
    /// Use property observer to save changes immidiatly
    var takeName = "default" {
        didSet {
            coreDataController?.updateUserSetting(name: "takename", value: takeName)
        }
    }
    var takeNameExtension = "index"
    
    var style = "dark"
    var recordingsetting = "middle"
    var shareClient = "iCloud"
    
    init() {
        //readSettingsDefinitions()
        if coreDataController != nil {
            fetchUserSettings()
        }
    }
    
    
    private func fetchUserSettings() {
        userSettingsMO = (coreDataController?.fetchUserSettings())!
        
        if userSettingsMO.isEmpty {
            seedUserSettings()
            
        } else {
            let activeSetting = userSettingsMO.first!
            takeName = activeSetting.takename!
            style = activeSetting.style!
            recordingsetting = activeSetting.recordingSettings!
            takeNameExtension = activeSetting.takenameExtension!
            
            if activeSetting.shareClient != nil {
                shareClient = activeSetting.shareClient!
            }
            
        }
    }
    
    
    func seedUserSettings() {
        var defaultSettings = [String: String]()
        
        defaultSettings["takeName"] = takeName
        defaultSettings["style"] = style
        defaultSettings["recordingSettings"] = recordingsetting
        defaultSettings["shareClient"] = shareClient
        
        coreDataController?.seedUserSettings(settings: defaultSettings)
    }
    
    func updateUserSetting(name: String, value: String) {
        switch name {
        case "takename":
            takeName = value
        case "takenameExtension":
            takeNameExtension = value
        case "style":
            style = value
        case "recordingSettings":
            recordingsetting = value
        case "shareClient":
            shareClient = value
            
        default:
            print("Unknown setting name: \(name)")
        }
        
        coreDataController?.updateUserSetting(name: name, value: value)
    }
    
    
    func userSettingsForDisplay() -> [String: String] {
        return ["takeNamePreset": takeName,
                "takeNameExtension": takeNameExtension,
                "style": style,
                "recordingSetting": recordingsetting,
                "shareClient": shareClient
        ]
    }
    
}
