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
    
    var userSettings = [UserSettingsMO]()
 
    /// Use property observer to save changes immidiatly
    var takeName = "default" {
        didSet {
            coreDataController?.updateUserSetting(name: "TakeName", value: takeName)
        }
    }
    
    var style = "dark"
    var recordingsetting = "high"
    
    init() {
        if coreDataController != nil {
            fetchUserSettings()
        }
    }
    
    
    private func fetchUserSettings() {
        userSettings = (coreDataController?.fetchUserSettings())!
        
        if userSettings.isEmpty {
            seedUserSettings()
            
        } else {
            let activeSetting = userSettings.first!
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
    
    
    /**
     Return array of user settings
     
     */
    func getUserSettingsForDisplay() -> [[String]] {
        
        var userSettingsValues = [[String]]()
        userSettingsValues.append(["Recording Settings", recordingsetting])
        userSettingsValues.append(["Style", style])
        userSettingsValues.append(["Take Name Preset",takeName])
        
        return userSettingsValues
    }
}

