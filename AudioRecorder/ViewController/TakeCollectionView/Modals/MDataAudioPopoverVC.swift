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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        statusLabel.isHidden = true
        recordBtn.isEnabled = false
        if take != nil {
            if recordingType == .NOTE {
                if let takeName = take?.takeName {
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let noteTakePath = documentsURL.appendingPathComponent(RecordingTypes.NOTE.rawValue)
                    do {
                        try FileManager.default.createDirectory(at: noteTakePath, withIntermediateDirectories: true, attributes: nil)
                        //noteTakePath.appendPathExtension((take?.takeType)!)
                        recorder = Recorder(takeName: takeName, takeURL: noteTakePath)
                        recordBtn.isEnabled = true
                        if ((take?.getNoteForTake()) != nil)  {
                            statusLabel.isHidden = false
                        }
                    } catch {
                        print(error.localizedDescription)
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
            
            if recorder?.startRecording() == true {
                recording = true
                recordingTimer.startTimer()
            }
            
            
            
        } else {
            sender.tintColor = UIColor.lightGray
            
            if (recorder?.stopRecording(success: true))! {
                recordingTimer.stopTimer()
                recording = false
                
                // save note to audio MetadataItem
                take?.updateItem(id: "audio", value: (take?.takeName)!, section: .METADATASECTION)
            }
            
        }
    }
    
    
    @IBAction func finishBtnAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}