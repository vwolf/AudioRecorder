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
    var useDropbox = false
    var useICloud = true
    
    init() {
        //readSettingsDefinitions()
        //setUserDefaults(key: "useDropbox", value: true)
        if coreDataController != nil {
            fetchUserSettings()
        }
        
        
    }
    
    func getUserDefaults(key: String) -> Any? {
        
        switch key {
        case "useDropbox":
            return UserDefaults.standard.bool(forKey: key)
        case "useICloud" :
            return useICloud
        default:
            return nil
        }
    }
    
    func getUserDefaultsAsString(key: String) -> String? {
        
        switch key {
        case "useDropbox":
            let useDropbox = UserDefaults.standard.bool(forKey: key)
            return String(useDropbox)

        case "useICloud":
            return String(useICloud)
            
        default:
            return nil
        }
    }
    
    func setUserDefaults(key: String, value: Any) {
        print("UserDefault \(key) to \(value)")
        switch key {
        case "useDropbox":
            UserDefaults.standard.set(value, forKey: key)
            
        case "useICloud":
            UserDefaults.standard.set(useICloud, forKey: key)
            
        default:
            print("No key \(key) in UserDefaults.standard")
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
            useICloud = (getUserDefaults(key: "useICloud") ?? true) as! Bool
            useDropbox = (getUserDefaults(key: "useDropbox") ?? false) as! Bool
            
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
        //defaultSettings["shareClient"] = shareClient
        defaultSettings["useICloud"] = String(useICloud)
        defaultSettings["useDropbox"] = String(useDropbox)
        
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
    
    func updateUserDefaults(name: String, value: Any) {
        switch name {
        case "useDropbox":
            useDropbox = value as! Bool
        case "useICloud":
            useICloud = value as! Bool
        default:
            print(name)
        }
        
        setUserDefaults(key: name, value: value)
    }
    
    
    func userSettingsForDisplay() -> [String: String] {
        //"shareClient": shareClient,
        return ["takeNamePreset": takeName,
                "takeNameExtension": takeNameExtension,
                "style": style,
                "recordingSetting": recordingsetting,
                "useICloud": String(useICloud),
                "useDropbox": String(useDropbox)
        ]
    }
    
}
