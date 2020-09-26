//
//  Settings.swift
//  AudioRecorder
//
//  Created by Wolf on 05.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

/**
 At first use, write predefined recording format setting into coreData
 After that, fetch settings and use recording format which is saved in UserSetting-> recordingSetting
 
 */
class Settings {
    
    /// get CoreDataController
    var coreDataController = (UIApplication.shared.delegate as! AppDelegate).coreDataController
    
    var recordingSettings = [SettingsMO]()
    
    var defaultSetting = [
        AVFormatIDKey : Int(kAudioFormatLinearPCM),
        AVSampleRateKey : 44.100,
        AVNumberOfChannelsKey : 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ] as [String : Any]
    
    var currentSetting: String = "Default"
    
    init(name: String) {
        currentSetting = name
        recordingSettings = (coreDataController?.fetchSettings())!
        
        if recordingSettings.isEmpty {
            // no settings in coreData, seed presets
            seedPresetSettings()
        }
    }
    
    /**
     Return setting with parameter name else defaultSetting
     
     - Parameters:
        - name: property name of setting
    */
    func getSetting(name: String) -> [String: Any] {
        guard let setting = recordingSettings.first(where: {$0.name == name} ) else {
            print("No setting with name \(name)")
            currentSetting = "Default"
            return defaultSetting
        }
        
//        AVAudioQuality : AVAudioQuality.high.rawValue,
        let settings = [
            AVFormatIDKey : Int(kAudioFormatLinearPCM),
            
            AVSampleRateKey : setting.sampleRate,
            AVNumberOfChannelsKey : setting.channels,
            AVLinearPCMBitDepthKey: setting.bitDepth,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ] as [String : Any]
        
        currentSetting = setting.name!
        
        return settings
    }
    
    
    func getCurrentSetting() -> [String: Any] {
        if currentSetting != "default" {
            return getSetting(name: currentSetting)
        }
        return defaultSetting
    }
    
    
    /**
     Return current settings as array for display in table
     
     */
    func getSettingForDisplay(name: String) -> [[String]] {
        let setting = getSetting(name: name)
        
        let settingsDict = [
            ["Name", currentSetting],
            ["SampleRate", String(format: "%.3f", setting[AVSampleRateKey] as! CVarArg )],
            ["Bitdepths", "\(setting[AVLinearPCMBitDepthKey] as! CVarArg)" ] ,
            ["Channels", "\(setting[AVNumberOfChannelsKey] as! CVarArg)" ],
            ["Format", "\(setting[AVFormatIDKey] as! CVarArg)" ]
        ]
        
        return settingsDict
    }
   
        
    
    /**
     Write presets to Coredata. This happens only at first application start
     
    */
    func seedPresetSettings() {
        var presets = [[String: Any]]()
        presets.append(["name": "high", "type": "wav", "bitDepth": 24 as Int16, "sampleRate": 48.000, "channels": 1 as Int16])
        presets.append(["name": "middle", "type": "wav", "bitDepth": 16 as Int16, "sampleRate": 41.100, "channels": 1 as Int16])
        presets.append(["name": "low", "type": "wav", "bitDepth": 8 as Int16, "sampleRate": 22.050, "channels": 1 as Int16])
        
        coreDataController?.seedSettings(settings: presets)
    }
    
    
}

/**
 Setting data
 */
struct Setting {
    
    var name: String
    var format: SettingDefinitions.SettingFormat
    var value: String
}

/**
 All predefined setting ( Format and User Settings)
 
 */

enum SettingDefinitions: CaseIterable {
    // recording format
    case recordingFormatName
    case recordingFormatType
    case bitDepth
    case sampleRate
    case channels
    
    // user settings
    case takeName
    case style
    case recordingSetting
    
    func getSetting() -> Setting {
        switch self {
        case .recordingFormatName:
            return Setting(name: "Preset Name", format: SettingFormat.fixed, value: "Default")
        case .recordingFormatType:
            return Setting(name: "Type", format: SettingFormat.fixed, value: "Default")
        case .bitDepth:
            return Setting(name: "Bitdepth", format: SettingFormat.fixed, value: "Default")
        case .sampleRate:
            return Setting(name: "SampleRate", format: SettingFormat.fixed, value: "Default")
        case .channels:
            return Setting(name: "Channels", format: SettingFormat.fixed, value: "Default")
        case .takeName:
            return Setting(name: "Preset Name", format: SettingFormat.userDefined, value: "Default")
        case .style:
            return Setting(name: "Style", format: SettingFormat.preset, value: "Default")
        case .recordingSetting:
            return Setting(name: "Name of recording Setting", format: SettingFormat.fixed, value: "Default")
        }
    }
    
    
    enum SettingFormat: String {
        case preset = "preset"
        case userDefined = "userDefined"
        case fixed = "fixed"
    }
}


//enum Constants : String {
//    case takesFolder = "takes"
//    case notesFolder = "notes"
//}


enum AppConstants: String {
    case takesFolder = "takes"
    case notesFolder = "notes"
}

