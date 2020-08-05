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
     Write presets to Coredata. This happens only at first application start
     
    */
    func seedPresetSettings() {
        var presets = [[String: Any]]()
        presets.append(["name": "High", "type": "wav", "bitDepth": 24 as Int16, "sampleRate": 48.000, "channels": 1 as Int16])
        presets.append(["name": "Middle", "type": "wav", "bitDepth": 16 as Int16, "sampleRate": 41.100, "channels": 1 as Int16])
        presets.append(["name": "Low", "type": "wav", "bitDepth": 8 as Int16, "sampleRate": 22.050, "channels": 1 as Int16])
        
        coreDataController?.seedSettings(settings: presets)
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

