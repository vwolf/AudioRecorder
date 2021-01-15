//
//  MDataAudioPopoverVC.swift
//  AudioRecorder
//
//  Created by Wolf on 30.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class MDataAudioPopoverVC: UIViewController {

    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var finishBtn: UIButton!
    @IBOutlet weak var recordingTimer: RecordingTimer!
    @IBOutlet weak var statusLabel: UILabel!
    
    var take: Take?
    var recording = false
    var recordingType: RecordingTypes = RecordingTypes.TAKE
    var recorder: Recorder?
    
    var noteURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        statusLabel.isHidden = true
        recordBtn.isEnabled = false
        if take != nil {
            if recordingType == .NOTE {
                if let takeName = take?.takeName {
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    var noteTakePath = documentsURL.appendingPathComponent(RecordingTypes.TAKE.rawValue, isDirectory: true)
                    noteTakePath.appendPathComponent(takeName, isDirectory: true)
                    
                    // there should always a directory named takeName
                    if FileManager.default.fileExists(atPath: noteTakePath.path)  {
                        noteTakePath.appendPathComponent(takeName + AppConstants.notesFileExtension.rawValue)
                        noteTakePath.appendPathExtension("wav")
                        noteURL = noteTakePath
                        
                        recorder = Recorder()
                        
                        if recorder!.recordingSessionStatus == true {
                            recordBtn.isEnabled = true
                        } else {
                            recorder?.initSession()
                            recordBtn.isEnabled = true
                        }
//                        recorder = Recorder(takeName: takeName, takeURL: noteTakePath)
//                        recordBtn.isEnabled = true
                        
                        if ((take?.getNoteForTake()) != nil)  {
                            statusLabel.isHidden = false
                        }
                    } else {
                        print("Error no directory for take note audio file")
                    }
                }
            }
       
            // note for take?
            
        }
    }



    @IBAction func recordBtnAction(_ sender: UIButton) {
        if recording == false {
            
            let originalImg = sender.image(for: .normal)
            let tintedImg = originalImg?.withRenderingMode(.alwaysTemplate)
            sender.setImage(tintedImg, for: .normal)
            sender.tintColor = Colors.Base.baseRed.toUIColor()
            
            if recorder?.startRecording(takeURL: noteURL!) == true {
                recording = true
                recordingTimer.startTimer()
            }
        } else {
            sender.tintColor = UIColor.lightGray
            
            if (recorder?.stopRecording(success: true))! {
                recordingTimer.stopTimer()
                recording = false
                
                // save note to audio MetadataItem
                if take?.updateItem(id: "audioNote", value: (noteURL?.lastPathComponent)!, section: .METADATASECTION) == false {
                    print("Could not update item")
                } else {
                    _ = take?.saveMetadataItem(id: "audioNote", section: .METADATASECTION)
                }
            }
            
        }
    }
    
    
    @IBAction func finishBtnAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
