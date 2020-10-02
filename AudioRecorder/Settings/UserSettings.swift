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
    var userSettings = [UserSetting]()
    
    /// Use property observer to save changes immidiatly
    var takeName = "default" {
        didSet {
            coreDataController?.updateUserSetting(name: "takename", value: takeName)
        }
    }
    
    var style = "dark"
    var recordingsetting = "middle"
    
    init() {
        readSettingsDefinitions()
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
        }
    }
    
    
    func seedUserSettings() {
        var defaultSettings = [String: String]()
        
        defaultSettings["takeName"] = takeName
        defaultSettings["style"] = style
        defaultSettings["recordingSettings"] = recordingsetting
        
        coreDataController?.seedUserSettings(settings: defaultSettings)
    }
    
    func updateUserSetting(name: String, value: String) {
        switch name {
        case "takename":
            takeName = value
        case "style":
            style = value
        case "recordingSettings":
            recordingsetting = value
        default:
            print("Unknown setting name: \(name)")
        }
        
        coreDataController?.updateUserSetting(name: name, value: value)
    }
    
    
    /**
     Return array of user settings
     
     */
    func getUserSettingsForDisplay() -> [[String]] {
        
        var userSettingsValues = [[String]]()
        
        for settingDefinition in userSettings {
            userSettingsValues.append( [ settingDefinition.name, settingDefinition.value ]  )
        }
//        userSettingsValues.append(["Recording Settings", recordingsetting])
//        userSettingsValues.append(["Style", style])
//        userSettingsValues.append(["Take Name Preset", takeName])
        
        return userSettingsValues
    }
    
    func userSettingsForDisplay() -> [String: String] {
        return ["takeNamePreset": takeName, "style": style, "recordingSetting": recordingsetting]
    }
    /**
     Read UserSettings into dict
     
     */
    func readSettingsDefinitions() {
        for userSetting in UserSettingsDefinitions.allCases {
            userSettings.append(userSetting.getUserSetting())
        }
    }
    
}


enum UserSettingsDefinitions: CaseIterable {
    case takeName
    case style
    case recordingSetting

    func getType() -> SettingType {
        switch self {
        case .takeName:
            return SettingType.userDefined
        case .style:
            return SettingType.preset
        default:
            return SettingType.fixed
        }
    }
    
    func getDefinition() -> [String: String] {
        switch self {
        case .takeName:
            return ["name": "Take Name Preset", "type": getType().rawValue, "default": "recorde"]
        case .style:
            return ["name": "Style", "type": getType().rawValue, "default": "dark"]
        case .recordingSetting:
            return ["name": "Recording Setting", "type": getType().rawValue, "default": "middle"]
        }
    }
    
    func getUserSetting() -> UserSetting {
        switch self {
        case .takeName:
            return UserSetting(name: "Take Name Preset", type: getType().self, value: "recorde")
        case .style :
            return UserSetting(name: "Style", type: getType().self, value: "dark")
        case .recordingSetting:
            return UserSetting(name: "RecordingSetting", type: getType().self, value: "middle")
        }
    }
    
    
    enum SettingType: String {
        case preset = "preset"
        case userDefined = "userDefined"
        case fixed = "fixed"
        
    }
}


struct UserSetting {
    var name: String
    var type: UserSettingsDefinitions.SettingType
    var value: String
    
    init(name: String, type: UserSettingsDefinitions.SettingType, value: String) {
        self.name = name
        self.type = type
        self.value = value
    }
}


