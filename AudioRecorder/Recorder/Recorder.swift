//
//  Recorder.swift
//  AudioRecorder
//
//  Created by Wolf on 30.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import AVFoundation

class Recorder: NSObject, AVAudioRecorderDelegate {
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var takeName: String?
    var takeURL: URL?
    
    init(takeName: String?, takeURL: URL?) {
        super.init()
        
        self.takeName = takeName
        self.takeURL = takeURL
        
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSession.Category.record)
            try recordingSession.setActive(true)
            
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                if allowed {
                    print("Recording allowed \(String(describing: self.takeName))")
                }
            }
        } catch {
            print("Error initializing recordinSession \(error)")
        }
        
    }
    
    /**
     Get full path for recoding file.
     Recordig settings
    */
    func startRecording() -> Bool {
        
        let defaultSetting = [
            AVFormatIDKey : Int(kAudioFormatLinearPCM),
            AVSampleRateKey : 44.100,
            AVNumberOfChannelsKey : 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ] as [String : Any]
        
        do {
            // update takeURL with format extension
            takeURL?.appendPathComponent(takeName!)
            takeURL?.appendPathExtension("wav")
            audioRecorder = try AVAudioRecorder(url: takeURL!, settings: defaultSetting)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            return true
        } catch {
            print("Error recording \(error.localizedDescription)")
        }
        
        return false
    }
    
    
    /**
     Recording end event message.
     In case of an error during recording, audioRecorder delegate calls this function
     
     - parameter success: recording successful
     */
    func stopRecording(success: Bool) -> Bool {
        if (audioRecorder != nil) {
            NSLog("stop recording take \(audioRecorder.url), success: \(success)")
            
            if success {
                audioRecorder.stop()
                audioRecorder = nil
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
}


enum RecordingTypes: String {
    case TAKE = "takes"
    case NOTE = "notes"
}
