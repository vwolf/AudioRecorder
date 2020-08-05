//
//  RecordVC.swift
//  AudioRecorder
//
//  Created by Wolf on 04.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation


class RecordVC: UIViewController {

    @IBOutlet weak var recordBtn: UIButton!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    @IBOutlet weak var recordngTimer: RecordingTimer!
    
    var recording = false {
        didSet {
            if recording {
                let orginialImg = recordBtn.image(for: .normal)
                let tintedImg = orginialImg?.withRenderingMode(.alwaysTemplate)
                recordBtn.setImage(tintedImg, for: .normal)
                recordBtn.tintColor = UIColor.orange
            } else {
                recordBtn.tintColor = UIColor.white
            }
        }
    }
    
    var takeNamePreset = "takeNamePreset"
    
    var settings: Settings?
    var userSettings: UserSettings?
//    var userSettings: UserSettings = UserSettings.init() {
//        didSet {
//            takeNamePreset = userSettings.takeName + " + timeStamp"
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        recordngTimer.isHidden = true
    }
    

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        NSLog("prepare for segue \(String(describing: segue.identifier))")
        
        switch segue.identifier {
        case "ShowSettingsSegueIdentifier":
            let destination = segue.destination as? SettingsVC
            if settings == nil {
                initSettings()
                let settingsList = settingsToList()
                let userSettingsList = userSettingsToList()
                destination?.tableData = [settingsList, userSettingsList]
            }
        default:
            NSLog("Navigation: Segue with unknown identifier")
        }
    }
    
    
    
    // MARK: Actions
    /**
     Recording button behavoir:
     First touch (no Take object): just start recording session
     Touch after recording (Take object exists): Save take?
     Touch when recording: stop recording
     
     InputDialog:cancel -> don't save take, which means delete take as the
     take is save during recording with default name
    */
    @IBAction func recordBtnAction(_ sender: UIButton) {
        if !recording {
            recording = true
            recordngTimer.isHidden = false
            recordngTimer.startTimer()
        } else {
            recording = false
            recordngTimer.stopTimer()
        }
    }
    
    // MARK: Settings And UserSettings
    
    private func initSettings(name: String = "High") {
        if settings == nil {
            settings = Settings(name: name)
        }
    }
    
    private func settingsToList() -> [[String]] {
        let currentSetting = settings?.getCurrentSetting()
        var settingsName = "Default"
        
        if settings?.currentSetting != nil {
            settingsName = (settings?.currentSetting)!
        }
        
        let settingsList = [
            ["Name", settingsName],
            ["Samplerate", String(format: "%.3f", currentSetting?[AVSampleRateKey] as! CVarArg) ],
            ["Bitdepths", "\(currentSetting?[AVLinearPCMBitDepthKey] as! CVarArg)" ],
            ["Channels", "\(currentSetting?[AVNumberOfChannelsKey] as! CVarArg)" ],
            ["Format", "\(currentSetting?[AVFormatIDKey] as! CVarArg)" ],
            ["Takename", "\(userSettings?.takeName ?? "default")"]
        ]
        
        return settingsList
    }
    
    private func userSettingsToList() -> [[String]] {
        
        
        if userSettings == nil {
            userSettings = UserSettings.init()
        } else {
            //userSettings?.takeName
        }
        
        takeNamePreset = userSettings?.takeName ?? takeNamePreset + " + timeStamp"
        
        let userSettingsList = [
            ["Take name preset", userSettings?.takeName],
            ["Style", userSettings?.style],
            ["RecordingSetting", userSettings?.recordingsetting]
        ]
        
        return userSettingsList as! [[String]]
    }
}
