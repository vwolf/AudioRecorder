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
        AVSampleRateKey : 44100.0,
        //AVNumberOfChannelsKey : 1,
        AVLinearPCMBitDepthKey: 16
        //AVLinearPCMIsFloatKey: false,
        //AVLinearPCMIsBigEndianKey: false
        //AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ] as [String : Any]
    
    var currentSettingsName: String = "Default"
    var currentSetting: [Setting]?
    
    /// order of items for display
    let formatSettingsOrder = ["name", AVFormatIDKey, AVSampleRateKey, AVNumberOfChannelsKey, AVLinearPCMBitDepthKey]
    let userSettingsOrder = ["takename", "takeNameExtension", "recordingSettings", "style", "useICloud", "useDropbox"]
    
    init(name: String) {
        currentSettingsName = name
        recordingSettings = (coreDataController?.fetchSettings())!
        
        if recordingSettings.isEmpty {
            // no settings in coreData, seed presets
            if seedPresetSettings() == true {
                recordingSettings = (coreDataController?.fetchSettings())!
            }
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
            currentSettingsName = "Default"
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
        
        currentSettingsName = setting.name!
        
        return settings
    }
    
    
    func getCurrentSetting() -> [String: Any] {
        if currentSettingsName != "default" {
            //return defaultSetting
            return getSetting(name: currentSettingsName)
        }
        return defaultSetting
    }
    
    func updateSetting() {
        
    }
    /**
     Return current settings as array for display in table
     
     */
    func getSettingForDisplay(name: String) -> [[String]] {
        let setting = getSetting(name: name)
        
        let settingsDict = [
            ["Name", currentSettingsName],
            ["SampleRate", String(format: "%.3f", setting[AVSampleRateKey] as! CVarArg )],
            ["Bitdepths", "\(setting[AVLinearPCMBitDepthKey] as! CVarArg)" ] ,
            ["Channels", "\(setting[AVNumberOfChannelsKey] as! CVarArg)" ],
            ["Format", "\(setting[AVFormatIDKey] as! CVarArg)" ]
        ]
        
        return settingsDict
    }
   
    func getSettingsName() -> [String] {
        var settingNames = [String]()
        
        for setting in recordingSettings {
            settingNames.append(setting.name!)
        }
        return settingNames
    }
    
    /**
     Write presets to Coredata. This happens only at first application start
     
    */
    func seedPresetSettings() -> Bool {
        var presets = [[String: Any]]()
        //var settingStructs = [String: [Setting]]()
        
        presets.append(["name": "high", "type": "wav", "bitDepth": 24 as Int16, "sampleRate": 48000.0, "channels": 1 as Int16])
        presets.append(["name": "middle", "type": "wav", "bitDepth": 16 as Int16, "sampleRate": 44100.0, "channels": 1 as Int16])
        presets.append(["name": "low", "type": "wav", "bitDepth": 16 as Int16, "sampleRate": 22050.0, "channels": 1 as Int16])
        
        return ((coreDataController?.seedSettings(settings: presets)) != nil)
    }
    
    /**
     Return setting to be displayed in Settings Screen
        Get the Settings Struct , then update value
     
     */
    func settingForDisplay(name: String) -> [Setting] {
        let currentSetting = getSetting(name: name)
//        let currentSettingDisplay = getSettingForDisplay(name: name)
//        var settingStructs = [String: [Setting]]()
        var settingToAdd = [Setting]()
        //
        let recordingFormatNameSetting = SettingDefinitions.recordingFormatName.getSetting(value: name)
        settingToAdd.append(recordingFormatNameSetting)
        
        for setting in currentSetting {
            switch setting.key {
            case AVFormatIDKey :
                let format = formatTypeToExtension(format: setting.value as! Int)
//                let settingValue = String(describing: setting.value as! CVarArg)
                let settingStruct = SettingDefinitions.recordingFormatType.getSetting(value: format)
                settingToAdd.append(settingStruct)
            case AVLinearPCMBitDepthKey:
                let settingValue = String(describing: setting.value as! CVarArg)
                let settingStruct = SettingDefinitions.bitDepth.getSetting(value: settingValue)
                settingToAdd.append(settingStruct)
            case AVSampleRateKey:
                let settingValue = String(format: "%.3f", setting.value as! CVarArg )
                let settingStruct = SettingDefinitions.sampleRate.getSetting(value: settingValue)
                settingToAdd.append(settingStruct)
            case AVNumberOfChannelsKey:
                let settingValue = String(describing: setting.value as! CVarArg)
                let settingStruct = SettingDefinitions.channels.getSetting(value: settingValue)
                settingToAdd.append(settingStruct)
//            case AVLinearPCMIsBigEndianKey:
//                let settingValue = String(describing: setting.value as! CVarArg)
//                let settingStruct = SettingDefinitions.bigEndian.getSetting(value: settingValue)
//                settingToAdd.append(settingStruct)
            default:
                print("Unknown")
            }
        }
        
        let sorted = settingToAdd.sorted { formatSettingsOrder.firstIndex(of: $0.id)! < formatSettingsOrder.firstIndex(of: $1.id)!}
        return sorted
    }
    
    
    func userSettingsForDisplay(data: [String: String]) -> [Setting] {
        var settingToAdd = [Setting]()
        
        for set in data {
            switch set.key {
            case "takeNamePreset":
                let settingStruct = SettingDefinitions.takeName.getSetting(value: set.value)
                settingToAdd.append(settingStruct)
            case "takeNameExtension":
                let settingStruct = SettingDefinitions.takeNameExtension.getSetting(value: set.value)
                settingToAdd.append(settingStruct)
            case "style":
                let settingStruct = SettingDefinitions.style.getSetting(value: set.value)
                settingToAdd.append(settingStruct)
            case "recordingSetting":
                let settingStruct = SettingDefinitions.recordingSetting.getSetting(value: set.value)
                settingToAdd.append(settingStruct)
//            case "shareClient":
//                let settingStruct = SettingDefinitions.shareClient.getSetting(value: set.value)
//                settingToAdd.append(settingStruct)
            case "useICloud" :
                settingToAdd.append(SettingDefinitions.useICloud.getSetting(value: set.value))
            case "useDropbox" :
                let settingStruct = SettingDefinitions.useDropbox.getSetting(value: set.value)
                settingToAdd.append(settingStruct)
            
            default:
                print("Unknown")
            }
        }
        
        let sorted = settingToAdd.sorted { userSettingsOrder.firstIndex(of: $0.id)! < userSettingsOrder.firstIndex(of: $1.id)! }
        
        return sorted
    }
    
    private func formatTypeToExtension(format: Int) -> String {
        print(format)
        print(kAudioFormatLinearPCM)
        print(Int(kAudioFormatLinearPCM))
        if format == kAudioFormatLinearPCM {
            return "wav"
        }
        return String(format)
    }
}

/**
 Setting data
 */
struct Setting {
    var name: String
    var format: SettingDefinitions.SettingFormat
    var value: String
    
    var id: String
    var settingEditingParms: SettingEditingParams?
}

struct SettingEditingParams {
    var title: String
    var msg: String?
    var presets: [String]
    var presetsMsg: [String]
    
    func getPresetMsg(value: String) -> String {
        let idx = presets.firstIndex(where: { $0 == value })
        if idx != nil {
            if presetsMsg.count > idx! {
                return presetsMsg[idx!]
            }
        }
        return value
    }
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
    case bigEndian
    
    // user settings
    case takeName
    case takeNameExtension
    case style
    case recordingSetting
    case shareClient
    case useICloud
    case useDropbox
    
    func getSetting(value: String) -> Setting {
        switch self {
        case .recordingFormatName:
            return Setting(name: "Recording Setting", format: SettingFormat.fixed, value: value, id: "name")
        case .takeNameExtension:
            let params = self.getSettingEditingParams()
            return Setting(name: "Name Extension", format: SettingFormat.preset, value: value, id: "takeNameExtension", settingEditingParms: params)
        case .recordingFormatType:
            return Setting(name: "Type", format: SettingFormat.fixed, value: value, id: AVFormatIDKey)
        case .bitDepth:
            return Setting(name: "Bitdepth", format: SettingFormat.fixed , value: value, id: AVLinearPCMBitDepthKey)
        case .sampleRate:
            return Setting(name: "Samplerate", format: SettingFormat.fixed, value: value, id: AVSampleRateKey)
        case .channels:
            return Setting(name: "Channels", format: SettingFormat.fixed, value: value, id: AVNumberOfChannelsKey)
        case .bigEndian:
            return Setting(name: "Big Endian", format: SettingFormat.fixed, value: value, id: AVLinearPCMIsBigEndianKey)
        case .takeName:
            return Setting(name: "Preset Name", format: SettingFormat.userDefined, value: value, id: "takename")
        case .style:
            let params = self.getSettingEditingParams()
            return Setting(name: "Style", format: SettingFormat.preset, value: value, id: "style", settingEditingParms: params)
        case .recordingSetting:
            return Setting(name: "Name of Recording Setting", format: SettingFormat.preset, value: value, id: "recordingSettings")
        case .shareClient:
            let params = self.getSettingEditingParams()
            return Setting(name: "Service for sharing", format: SettingFormat.preset, value: value, id: "shareClient", settingEditingParms: params)
        case .useICloud:
            return Setting(name: "Use iCloud for sharing", format: SettingFormat.onoff, value: value, id: "useICloud")
        case .useDropbox:
            return Setting(name: "Use Dropbox for sharing", format: SettingFormat.onoff, value: value, id: "useDropbox")
        }
    }
    
    
    func getSettingEditingParams() -> SettingEditingParams {
        switch self {
        case .takeNameExtension:
            return SettingEditingParams(
                title: "Select Extension",
                msg: "Second part of take name",
                presets: ["date_index", "date_time", "index", "none"],
                presetsMsg: ["Date & Index", "Date & Time", "Index (0001)", "None"])
         
        case .style:
            return SettingEditingParams(title: "Select Display Style",
                                        msg: "ToDo",
                                        presets: ["dark", "light"],
                                        presetsMsg: ["Dark", "Light"])
            
        case .shareClient:
            return SettingEditingParams(
                title: "Select Service to Share",
                msg: "Available Clients",
                presets: ["iCloud", "Dropbox"],
                presetsMsg: ["iCloud", "Dropbox"])
        

            
        case .recordingSetting:
            return SettingEditingParams(
                title: "Select Format",
                msg: "Defined Formats",
                presets: ["middle", "high", "low"],
                presetsMsg: ["Middle", "High", "Low"])
            
        default:
            print("no Editing params")
        }
        
        return SettingEditingParams(title: "", presets: [], presetsMsg: [])
    }
    
    
    /**
     Return presetMsg (for display) of id
     */
    func presetToPresetMsg(id: String, value: String) -> String {
        
        return ""
    }
    
    /**
     Setting editing format
     - preset: predefined values
     - userDefined:
      - fixed: can't be changed by user
     */
    enum SettingFormat: String {
        case preset = "preset"
        case userDefined = "userDefined"
        case fixed = "fixed"
        case onoff = "onoff"
    }
    
    
}


//enum Constants : String {
//    case takesFolder = "takes"
//    case notesFolder = "notes"
//}


enum AppConstants: String {
    case takesFolder = "takes"
    case notesFolder = "notes"
    case notesFileExtension = "_note"
    
}

