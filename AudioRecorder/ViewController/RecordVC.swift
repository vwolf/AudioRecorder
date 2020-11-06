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
import CoreLocation

/**
 
 */
class RecordVC: UIViewController, AVAudioRecorderDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var recordBtn: UIButton!
    
    var take: Take?
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    @IBOutlet weak var recordingTimer: RecordingTimer!
    @IBOutlet weak var recordingName: UILabel!
    
    @IBOutlet weak var audioInputVisualizer: AudioInputVisualizer!
    
    @IBOutlet weak var toolbar: UIToolbar!
    
    var audioCaptureSession: AudioCaptureSession?
    
    /// observer recording state
    var recording = false {
        didSet {
            if recording {
                let orginialImg = recordBtn.image(for: .normal)
                let tintedImg = orginialImg?.withRenderingMode(.alwaysTemplate)
                recordBtn.setImage(tintedImg, for: .normal)
                recordBtn.tintColor = Colors.Base.baseRed.toUIColor()
                for i in 0..<toolbar.items!.count {
                    toolbar.items![i].isEnabled = false
                }
                
            } else {
                recordBtn.tintColor = Colors.Base.baseGreen.toUIColor()
                for i in 0..<toolbar.items!.count {
                    toolbar.items![i].isEnabled = true
                }
            }
        }
    }
    
    /// set after successfully recording
    var recorded = false
    /// this is the default takename preset string, can be changed at UserSettings
    var takeNamePreset = "recorded" {
        didSet {
            takeNamePreset = userSettings!.takeName
            recordingName.text = "\(takeNamePreset) + timestamp"
        }
    }
    
    var settings: Settings?
    var userSettings: UserSettings?
    
//    var userSettings: UserSettings = UserSettings.init() {
//        didSet {
//            takeNamePreset = userSettings.takeName + " + timeStamp"
//        }
//    }
    
    let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    
    /**
     Set background color for main view and audioInputVisualizer
     Initialize [recordBtn] to switch colors
     
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Colors.Base.background.toUIColor()
        audioInputVisualizer.backgroundColor = Colors.Base.background.toUIColor()
        
        let orginialImg = recordBtn.image(for: .normal)
        let tintedImg = orginialImg?.withRenderingMode(.alwaysTemplate)
        recordBtn.setImage(tintedImg, for: .normal)
        
        recordingTimer.isHidden = true
        recording = false
        
        initSettings()

        //userSettings?.takeName = takeNamePreset
        
        takeNamePreset = userSettings!.takeName
        recordingName.text = "\(takeNamePreset) + timestamp"
        
        audioInputVisualizer.setBarViewPosition()
        audioInputVisualizer.isHidden = true
        
        locationManager.requestWhenInUseAuthorization()
        // current location
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            userLocation = locationManager.location
            locationManager.startUpdatingLocation()
        }
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print(documentPath)
    }
    

    
    // MARK: - Navigation

    /**
     Before any navigation to new view, recording should stop and take saved.
     Always?
     
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        NSLog("prepare for segue \(String(describing: segue.identifier))")
        
        switch segue.identifier {
        case "ShowSettingsSegueIdentifier":
            let destination = segue.destination as? SettingsVC
            if settings != nil {
                destination?.settings = settings
                destination?.userSettings = userSettings
                
                if settings != nil {
//                    let settingData = settings!.getSettingForDisplay(name: userSettings?.recordingsetting ?? "default")
                    let displaySettingData = settings!.settingForDisplay(name: userSettings?.recordingsetting ?? "default")
                    //destination?.settingData.append(settingData)
                    destination?.displaySetting.append(displaySettingData)
                }
              
                if userSettings != nil {
//                    let userSettingData = userSettings!.getUserSettingsForDisplay()
                    let userDisplayData = userSettings!.userSettingsForDisplay()
                    let userDisplaySettingData = settings!.userSettingsForDisplay(data: userDisplayData)
                    //destination?.settingData.append(userSettingData)
                    destination?.displaySetting.append(userDisplaySettingData)
                }
            }
            
        case "ShowTakesSegueIdentifier" :
            let destination = segue.destination as? TakesVC
            
            let takes = Takes().getAllTakeNames(fileExtension: "wav", directory: nil, returnWithExtension: true)
            
            destination?.takes = takes
         
        // share destination depending on UserSettings
        // iCloudDrive, Dropbox
//        case "ShowShareSegueIdentifier":
//            if userSettings != nil {
//                switch userSettings?.shareClient {
//                case "iCloud" :
//                    let destination = segue.destination as? ShareVC
//                case "Dropbox" :
//                    let destination = segue.destination as? DropboxVC
//
//                default :
//                print("Unknown ShareClient")
//                }
//            }
//
//
        default:
            NSLog("Navigation: Segue with unknown identifier")
        }
    }
    
    
    @IBAction func shareBtnAction(_ sender: Any) {
        if userSettings != nil {
            switch userSettings?.shareClient {
            case "iCloud":
                self.performSegue(withIdentifier: "ShowShareSegueIdentifier", sender: self)
            case "Dropbox":
                self.performSegue(withIdentifier: "ShowDropboxSegueIdentifier", sender: nil)
            default:
                print("Unknown")
            }
        }
        //self.performSegue(withIdentifier: "ShowShareSegueIdentifier", sender: self)
    }
    
    
    // MARK: Actions
    /**
     Recording button behavoir:
     First touch (no Take object): just start recording session
     Touch after recording (Take object exists): Save take?
     Touch when recording: stop recording
     
     InputDialog:cancel -> don't save take, which means delete take as the
     take is save during recording with default name
     
     - parameter sender: UIButton
    */
    @IBAction func recordBtnAction(_ sender: UIButton) {
        if !recording {
            if recorded == false || take?.takeSaved == true  {
                startRecording()
            }
        } else {
            finishRecording(success: true)
        }
    }
    
    /**
     Start recording with [AVAudioRecorder](AVAudioRecorder).
     Start input level metering and  record timer.
     
     */
    private func startRecording() {
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let takeName = "\(userSettings!.takeName)_\(Date().toString(dateFormat: "dd-MM-YY_'at'_HH:mm:ss")).wav"
        let takeFileURL = documentPath.appendingPathComponent(takeName)
        NSLog(documentPath.path)
        
        let activeSettings = settings?.getCurrentSetting()
        print(activeSettings![AVSampleRateKey])
        
        //print(activeSettings[])
        do {
            audioRecorder = try AVAudioRecorder(url: takeFileURL, settings: activeSettings! )
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
            audioRecorder.isMeteringEnabled = true
            
            audioRecorder.record()
            
            recording = true
            recorded = false
            
            recordingTimer.isHidden = false
            recordingTimer.startTimer()
            
            audioInputVisualizer.isHidden = false
            audioInputVisualizer.startVisualize(audioRecorder: audioRecorder)
            recordingName.text = takeName
            
        } catch  {
            NSLog("Error startRecording")
        }
    }
    
    
    /**
     Recording finished event message
     
     - parameter success: recording successful
     */
    private func finishRecording(success: Bool) {
        let takeLength = audioRecorder.currentTime
        NSLog("Finish recording take (length: \(takeLength), success: \(success)")
        
        if success {
            let take = makeTake(audioRecorder: audioRecorder, length: takeLength)
            take.saveTake()
            
            recorded = false
        }
        
        audioRecorder.stop()
        recording = false
        recordingTimer.stopTimer()
        audioInputVisualizer.stopVisualize()
        audioInputVisualizer.isHidden = true
    }
    
    /**
     Make the Take object for recorded sound
     
     - Parameters:
        - audioRecorder: AVAudioRecorder instance used for recording take
        - length: length of recording
     
     - Returns: Take object
    */
    private func makeTake(audioRecorder: AVAudioRecorder, length: Double) -> Take {
        
        if userLocation == nil {
            userLocation = CLLocation()
        }
        let take = Take(takeURL: audioRecorder.url, date: Date(), userLocation: userLocation!)
        
//        _ = take.setURL(url: audioRecorder.url)
//        if (userLocation != nil) {
//            take.setLocation(location: userLocation!)
//        }
//        take.setRecordedAt(date: Date())
        
        //take.addCategory()
        
        return take
    }
    
    
    private func startCaptureSession() {
        audioCaptureSession = AudioCaptureSession.init()
    }
    
    // MARK: Settings And UserSettings
    
    /**
     First get [UserSetting](UserSettings), then load audio format setting depending on userSettings
     
     - Parameter name: name of recording format setting
     */
    private func initSettings(name: String = "middle") {
        if userSettings == nil {
            userSettings = UserSettings.init()
        }
        
        if settings == nil {
            settings = Settings.init(name: userSettings?.recordingsetting ?? name)
        }
        
        // userSettings needs recording setting names
        
    }
 
    
    // MARK: AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        NSLog("AudioRecorder Error: \(String(describing: error))")
    }
    
    
    // MARK: CAPTURE SESSION
    
    func initCaptureSession() {
        
//        let dev = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: .audio, position: .unspecified).devices
       
        let captureSession = AVCaptureSession()
//        guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
        let queue = DispatchQueue(label: "AudioSessionQueue", attributes: [])
        
        //guard let audioInputDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified) else { return }
        //let audioInputDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)!
        let audioInputDevice = AVCaptureDevice.default(for: .audio)!
        do {
            // wrap the audioInputDevice in a capture device input
            let audioInput = try AVCaptureDeviceInput(device: audioInputDevice)
            
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
            
            // output
            let audioOutput = AVCaptureAudioDataOutput()
            guard captureSession.canAddOutput(audioOutput) else { return }
            audioOutput.setSampleBufferDelegate(self, queue: queue)
            
            //captureSession.sessionPreset = .
            captureSession.addOutput(audioOutput)
            
            // start session
            captureSession.startRunning()
            
            
        } catch {
            NSLog(error.localizedDescription)
        }
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Data from captureSession received")
    }
}
