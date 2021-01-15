//
//  Recorder.swift
//  AudioRecorder
//
//  Created by Wolf on 30.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import AVFoundation

/// Recording class
/// Initialize the recordingSessing
/// - check premissions
/// - get input devices
///
/// ToDo: Connect to Settings to validat settings and to get user Settings
/// ToDo: Selection of input device if more then one device.
class Recorder: NSObject, AVAudioRecorderDelegate {
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var takeName: String?
    var takeURL: URL?
    
    var recordingSessionStatus: Bool = false
    
    /// AVAudioSession properties
    var inputGain: Float = 0.0
    var inputGainSettable: Bool = false
    
    var recordingFormatSetting: [String: Any]?
    
    private var levelUpdateTimer: Timer?
    
    init(takeName: String, takeURL: URL) {
        super.init()
    }
    
    
    override init() {
        super.init()
   
        recordingSession = AVAudioSession.sharedInstance()
        
        /// request RecordPermission
//        if requestRecordingPermission() == .granted {
//            do {
//                if recordingSession.availableCategories.contains(.playAndRecord) {
//                    try recordingSession.setCategory(AVAudioSession.Category.playAndRecord)
//                }
//
//                try recordingSession.setActive(true)
//
//                if recordingSession.isInputAvailable {
//                    let availableInputs = recordingSession.availableInputs
//                    let it = availableInputs?.makeIterator()
//
//                    inputGain = recordingSession.inputGain
//                    inputGainSettable = recordingSession.isInputGainSettable
//
//                    print("###### AVAILABLE INPUTS #######")
//                    for input in it! {
//                        print("Descriptive name for input: \(input.portName)")
//                        print(input.portType)
//                        print(input.selectedDataSource ?? "Port doesn't support selecting between data sources")
//                        print(input.preferredDataSource ?? "Port doesn't support selecting between data sources")
//                    }
//
//                    print("NumberOfChannels: \(recordingSession.inputNumberOfChannels)")
//                    print("MaximumInputNumberOfChannels: \(recordingSession.maximumInputNumberOfChannels)")
//                    print("preferredInputNumberOfChannels: \(recordingSession.preferredInputNumberOfChannels)")
//
//                    // Collect Audio Device Settings
//                    print("InputGain: \(recordingSession.inputGain)")
//                    print("InputGainSettable: \(recordingSession.isInputGainSettable)")
//                    print("SampleRate: \(recordingSession.sampleRate)")
//                    print("preferredSampleRate: \(recordingSession.preferredSampleRate)")
//
//                    print("###### AVAILABLE INPUTS END #######")
//                    recordingSessionStatus = true
//
//                    try recordingSession.setActive(false)
//                } else {
//                    print("No audio input path availabel")
//                }
//            }catch {
//                print("Error initializing recordinSession \(error)")
//            }
//        } else {
//
//        }
    }
    
    func initSession() {
        do {
            if recordingSession.availableCategories.contains(.playAndRecord) {
                try recordingSession.setCategory(AVAudioSession.Category.playAndRecord)
            }
            
            try recordingSession.setActive(true)
            
            if recordingSession.isInputAvailable {
                let availableInputs = recordingSession.availableInputs
                let it = availableInputs?.makeIterator()
                
                inputGain = recordingSession.inputGain
                inputGainSettable = recordingSession.isInputGainSettable
                
                print("###### AVAILABLE INPUTS #######")
                for input in it! {
                    print("Descriptive name for input: \(input.portName)")
                    print(input.portType)
                    print(input.selectedDataSource ?? "Port doesn't support selecting between data sources")
                    print(input.preferredDataSource ?? "Port doesn't support selecting between data sources")
                }
                
                print("NumberOfChannels: \(recordingSession.inputNumberOfChannels)")
                print("MaximumInputNumberOfChannels: \(recordingSession.maximumInputNumberOfChannels)")
                print("preferredInputNumberOfChannels: \(recordingSession.preferredInputNumberOfChannels)")
                
                // Collect Audio Device Settings
                print("InputGain: \(recordingSession.inputGain)")
                print("InputGainSettable: \(recordingSession.isInputGainSettable)")
                print("SampleRate: \(recordingSession.sampleRate)")
                print("preferredSampleRate: \(recordingSession.preferredSampleRate)")
                
                print("###### AVAILABLE INPUTS END #######")
                recordingSessionStatus = true
                
                try recordingSession.setActive(false)
            } else {
                print("No audio input path availabel")
            }
        }catch {
            print("Error initializing recordinSession \(error)")
        }
    }
    
    func setInputGain(gain: Float) {
        self.inputGain = gain
        do {
            try recordingSession.setInputGain(gain)
        } catch {
            
        }
    }
    
    
    /// Get full path for recoding file.
    /// Recordig settings
    ///
    func startRecording(takeURL: URL) -> Bool {
        
        if recordingFormatSetting != nil {
            
        } else {
            recordingFormatSetting = [
                AVFormatIDKey : Int(kAudioFormatLinearPCM),
                AVSampleRateKey : 44100.0
            ]
        }
//        let defaultSetting = [
//            AVFormatIDKey : Int(kAudioFormatLinearPCM),
//            AVSampleRateKey : 44100.0,
////            AVNumberOfChannelsKey : 1,
////            AVLinearPCMBitDepthKey: 24,
////            AVLinearPCMIsFloatKey: false,
////            AVLinearPCMIsBigEndianKey: false,
////            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//        ] as [String : Any]
        
        do {
            try recordingSession.setActive(true)
            audioRecorder = try AVAudioRecorder(url: takeURL, settings: recordingFormatSetting!)
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()
            
            return true
        } catch {
            print("Error recording \(error.localizedDescription)")
        }
        
        return false
    }
    
    func startRecording() -> Bool {
        return true
    }
    
    
    func startInputLevel() {
        levelUpdateTimer = Timer.scheduledTimer(timeInterval: Double(0.05),
        target: self,
        selector: #selector(self.updateLevel),
        userInfo: nil,
        repeats: true)
    }
    
    @objc private func updateLevel() {
        
        audioRecorder.updateMeters()
        let power = averagePowerFromAllChannels()
        print(power)
        //setLevel(level: Float(power))
        
    }
    
    func averagePowerFromAllChannels() -> CGFloat {
       var power: CGFloat = 0.0
       
       (0..<(audioRecorder?.format.channelCount)!).forEach { (index) in
           power  = power + CGFloat((audioRecorder?.averagePower(forChannel: Int(index)))!)
       }
       
       return power / CGFloat( (audioRecorder?.format.channelCount)! )
   }
    
    
    /// Recording end event message.
    /// In case of an error during recording, audioRecorder delegate calls this function
    ///
    /// - parameter success: recording successful
    ///
    func stopRecording(success: Bool, activateSession: Bool = true) -> Bool {
        if (audioRecorder != nil) {
            NSLog("stop recording take \(audioRecorder.url), success: \(success)")
            
            if success {
                audioRecorder.stop()
                audioRecorder = nil
            }
            do {
                if activateSession {
                    try recordingSession.setActive(false)
                }
            } catch {
                print(error.localizedDescription)
            }
        } else {
            NSLog("stopRecording success false")
        }
        
        return success
    }

    
    
    // MARK:  AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            let _ = stopRecording(success: false)
        }
    }
    
    
    // MARK: AVAudioSession
    
    func requestRecordingPermission() -> AVAudioSession.RecordPermission {
        
        switch recordingSession.recordPermission {
        case .denied:
            print("RecordPermission by user denied!")
            return recordingSession.recordPermission
            
        case .granted:
            return recordingSession.recordPermission
            
        case .undetermined:
            // request permission
            recordingSession.requestRecordPermission() { allowed in
                if allowed {
                    print("RecordPermission granted")
                } else {
                    print("RecordPermission denied")
                }
            }
            
            return recordingSession.recordPermission
      
        @unknown default:
            print("Unkown AVAudioSession.RecordPermissen: \(recordingSession.recordPermission)")
            return recordingSession.recordPermission
        }
        
    }
    
    // MARK: AudioInputDeviceMonitor
    /// Start audio input capture session.
    /// AVCaptureSession runs async on main queue. Direct update of view is not possible. Start a timer to update to new level values.
    ///
}


enum RecordingTypes: String {
    case TAKE = "takes"
    case NOTE = "notes"
}

