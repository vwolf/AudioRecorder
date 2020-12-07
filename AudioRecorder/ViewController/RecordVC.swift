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

/// Recording screen
/// Initialization Settings, UserSettings ...
/// Option to set input device gain and display input device power level
/// When not recording use AVCaptureDevice else use AVAudioRecorder
///
class RecordVC: UIViewController, AVAudioRecorderDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var recordBtn: UIButton!
    
    var take: Take?
    var recorder: Recorder!
    
    @IBOutlet weak var recordingTimer: RecordingTimer!
    @IBOutlet weak var recordingName: UILabel!
    
    //@IBOutlet weak var audioInputVisualizer: AudioInputVisualizer!
    @IBOutlet weak var audioInputLevelView: AudioInputLevelView!
    @IBOutlet weak var audioInputGainView: AudioInputGainView!
    @IBOutlet weak var gainBtn: UIButton!
    @IBOutlet weak var levelBtn: UIButton!
    
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
            print("takeNamePreset to: \(takeNamePreset)")
            takeNamePreset = userSettings!.takeName
            recordingName.text = makeTakeName()
        }
    }
    /// name of take for next recording
    var takeName = "recorded" {
        didSet {
            recordingName.text = takeName
        }
    }
    
    var settings: Settings?
    var userSettings: UserSettings?
    let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    
    var audioInputDeviceMonitor: AudioInputDeviceMonitor!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
        
    }
    
    
    /// Set background color for main view and audioInputVisualizer
    /// Initialize [recordBtn] to switch colors.
    /// Read settings (user and format). Set a preset take name
    ///
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Colors.Base.background.toUIColor()
        //audioInputVisualizer.backgroundColor = Colors.Base.background.toUIColor()
        
        let orginialImg = recordBtn.image(for: .normal)
        let tintedImg = orginialImg?.withRenderingMode(.alwaysTemplate)
        recordBtn.setImage(tintedImg, for: .normal)
        recordBtn.isEnabled = false
        
        levelBtn.transform = levelBtn.transform.rotated(by: (.pi))
        recordingTimer.isHidden = true
        recording = false
        
        initSettings()
        
        takeNamePreset = userSettings!.takeName
        recordingName.text = "\(takeNamePreset)_\(userSettings!.takeNameExtension)"
        Takes()
        Takes.sharedInstance.getAllTakesInApp(directory: "takes", fileExtension: "wav")
        
        //audioInputLevelView.visible = false
        audioInputLevelView.isHidden = true
//        audioInputVisualizer.setBarViewPosition()
//        audioInputVisualizer.isHidden = true
        
        //audioLevelView.completion = audioLevelExtented(_:)
        
        locationManager.requestWhenInUseAuthorization()
        /// current location
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            userLocation = locationManager.location
            locationManager.startUpdatingLocation()
        }
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print(documentPath)
        
//        DispatchQueue.main.async {
//            CloudDataManager.sharedInstance.metadataQuery { [self] result in
//                print("metadataQuery return result \(result)")
//                //self.addToTakesInShare(takeURLs:  self.cloudDataManager.cloudURLs)
//                self.takeName = makeTakeName()
//            }
//        }
        
       /// setup Recorder ->  AVAudioSession  -> use completion closure to get result
        recorder = Recorder()
        if recorder.recordingSessionStatus == true {
            recordBtn.isEnabled = true
            //recorder.startInputLevel()
            
            if recorder.inputGainSettable == false {
                gainBtn.isEnabled = false
            }
        }
        
        /// TrackCKRecord's
        TakeCKRecordModel.sharedInstance.refresh {
            print("refreshClosure")
            if TakeCKRecordModel.sharedInstance.records.count > 0 {
                var takes = [String: URL]()
                for take in TakeCKRecordModel.sharedInstance.takeRecords {
                    takes[take.name] = take.audioAsset.fileURL
                    //print(take.name)
                }
                DispatchQueue.main.async {
                    Takes.sharedInstance.getAllTakesIniCloud()
                }
            }
        }
        
        Takes.sharedInstance.getAllTakesIniDrive()
        if UserDefaults.standard.bool(forKey: "useDropbox") {
            DropboxManager.sharedInstance.listFiles()
        }
    }
    

    
    // MARK: - Navigation

    
    /// Before any navigation to new view, recording should stop and take saved.
    /// Always?
    ///
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        NSLog("prepare for segue \(String(describing: segue.identifier))")
        
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case SegueIdentfiers.ShowSettingsDetails:
            let destination = segue.destination as? SettingsVC
            if settings != nil {
                destination?.settings = settings
                destination?.userSettings = userSettings
                
                if settings != nil {
                    let displaySettingData = settings!.settingForDisplay(name: userSettings?.recordingsetting ?? "default")
                    destination?.displaySetting.append(displaySettingData)
                }
              
                if userSettings != nil {
                    let userDisplayData = userSettings!.userSettingsForDisplay()
                    let userDisplaySettingData = settings!.userSettingsForDisplay(data: userDisplayData)
                    destination?.displaySetting.append(userDisplaySettingData)
                }
            }
            
        case SegueIdentfiers.ShowTakesDetails :
            let destination = segue.destination as? TakesVC
            let takes = Takes().getAllTakeNames()
            destination?.takes = takes
         
        default:
            NSLog("Navigation: Segue with unknown identifier")
        }
    }
    
    private enum SegueIdentfiers {
        static let ShowTakesDetails = "ShowTakesSegueIdentifier"
        static let ShowSettingsDetails = "ShowSettingsSegueIdentifier"
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
    
//    @IBAction func audioLevelViewTap(_ sender: Any) {
//        print("audioLevelViewTap")
//        // slide view into main view
//        audioLevelView.onMove()
//    }
    
    /// Show / Hide gain control view.
    /// Show only if an input device is available
    /// A change in AudioInputGainView.gain property is send to recorder to update gain
    ///
    @IBAction func gainBtnAction(_ sender: UIButton) {
        if recorder.inputGainSettable {
            sender.transform = sender.transform.rotated(by: (.pi))
            audioInputGainView.recorder = recorder
            audioInputGainView.gainSlider.value = recorder.inputGain
            audioInputGainView.gain = recorder.inputGain
            audioInputGainView.onMove()
        }
    }
    
    /// Show / Hide recording level view
    ///
    @IBAction func levelBtnAction(_ sender: UIButton) {
        sender.transform = sender.transform.rotated(by: .pi)
        audioInputLevelView.onMove()
       
    }
    
    /// Recording button behavoir:
    /// First touch (no Take object): just start recording session
    /// Touch after recording (Take object exists): Save take?
    /// Touch when recording: stop recording
    ///
    /// InputDialog:cancel -> don't save take, which means delete take as the
    /// take is save during recording with default name
    ///
    /// - parameter sender: UIButton
    @IBAction func recordBtnAction(_ sender: UIButton) {
        if !recording {
            if recorded == false || take?.takeSaved == true  {
                startRecorder()
            }
        } else {
           finishRecording(success: true)
        }
    }
    
    /// Start recording with Recorder
    /// Start input level metering and  record timer.
    ///
    private func startRecorder() {
        var documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // there should be a valid takeName, just check if unique
        if Takes.sharedInstance.getDirectoryForFile(takeName: takeName, takeDirectory: AppConstants.takesFolder.rawValue) != nil {
            // directory takeName exist in takes directiory
            takeName = makeTakeName()
        }
        
        let directoryName = takeName
        let takeName = directoryName + ".wav"
        
        documentPath.appendPathComponent("takes", isDirectory: true)
        
        if FileManager.default.fileExists(atPath: documentPath.path) == false {
            do {
                try FileManager.default.createDirectory(at: documentPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }

        // each takes gets a folder
        do {
            documentPath.appendPathComponent(directoryName, isDirectory: true)
            try FileManager.default.createDirectory(at: documentPath, withIntermediateDirectories: false, attributes: nil)
        } catch {
            print(error.localizedDescription)
        }

        let takeFileURL = documentPath.appendingPathComponent(takeName)

        NSLog("DocumentPath: \(documentPath.path)")
        NSLog(takeFileURL.path)
        
        let activeSettings = settings?.getCurrentSetting()
//        for val in activeSettings! {
//            print("key: \(val.key) value: \(val.value)")
//        }
        recorder?.recordingFormatSetting = activeSettings
        
        if recorder?.startRecording(takeURL: takeFileURL) == true {

            recordingTimer.isHidden = false
            recordingTimer.startTimer()

            recording = true
            recorded = false

//            audioInputVisualizer.isHidden = false
//            audioInputVisualizer.startVisualize(audioRecorder: recorder.audioRecorder)
            recordingName.text = takeName
            
        }
    }
    
    
    /**
     Start recording with [AVAudioRecorder](AVAudioRecorder).
     Start input level metering and  record timer.
     
     */
//    private func startRecording() {
//
//        var documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//
//        // there should be a valid takeName, just check if unique
//        if Takes().getDirectoryForFile(takeName: takeName, takeDirectory: AppConstants.takesFolder.rawValue) != nil {
//            // directory takeName exist in takes directiory
//            takeName = makeTakeName()
//        }
////        let nextIndex = Takes().getIndexForName(name: takeNamePreset, seperator: "_", type: "index",  indexLength: 4)
//        let directoryName = takeName
//
//        //let directoryName = "\(userSettings!.takeName)_\(Date().toString(dateFormat: "dd-MM-YY_'at'_HH:mm:ss"))"
//        //let takeName = "\(userSettings!.takeName)_\(Date().toString(dateFormat: "dd-MM-YY_'at'_HH:mm:ss")).wav"
//        let takeName = directoryName + ".wav"
//
//        documentPath.appendPathComponent("takes", isDirectory: true)
//        if FileManager.default.fileExists(atPath: documentPath.path) == false {
//            do {
//                try FileManager.default.createDirectory(at: documentPath, withIntermediateDirectories: false, attributes: nil)
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//
//        // each takes gets a folder
//        do {
//            documentPath.appendPathComponent(directoryName, isDirectory: true)
//            try FileManager.default.createDirectory(at: documentPath, withIntermediateDirectories: false, attributes: nil)
//        } catch {
//            print(error.localizedDescription)
//        }
//
//        let takeFileURL = documentPath.appendingPathComponent(takeName)
//        NSLog(documentPath.path)
//        NSLog(takeFileURL.path)
//
//        let activeSettings = settings?.getCurrentSetting()
//        //print(activeSettings![AVSampleRateKey])
//
//        //print(activeSettings[])
//        do {
//            audioRecorder = try AVAudioRecorder(url: takeFileURL, settings: activeSettings! )
//            audioRecorder.delegate = self
//            audioRecorder.prepareToRecord()
//            audioRecorder.isMeteringEnabled = true
//
//            audioRecorder.record()
//
//            recording = true
//            recorded = false
//
//            recordingTimer.isHidden = false
//            recordingTimer.startTimer()
//
//            audioInputVisualizer.isHidden = false
//            audioInputVisualizer.startVisualize(audioRecorder: audioRecorder)
//            recordingName.text = takeName
//
//        } catch  {
//            NSLog("Error startRecording")
//        }
//    }
    
    
    /**
     Recording finished event message
     
     - parameter success: recording successful
     */
    private func finishRecording(success: Bool) {
//        let takeLength = audioRecorder.currentTime
        let takeLength = recorder.audioRecorder.currentTime
        NSLog("Finish recording take (length: \(takeLength), success: \(success)")
        
        if success {
            let take = makeTake(audioRecorder: recorder.audioRecorder, length: takeLength)
            take.saveTake()
            
            recorded = false
        }
        
        //audioRecorder.stop()
        if audioInputLevelView.visible {
            recorder?.stopRecording(success: true, activateSession: false)
        } else {
            recorder.stopRecording(success: true)
        }
        recording = false
        recordingTimer.stopTimer()
//        audioInputVisualizer.stopVisualize()
//        audioInputVisualizer.isHidden = true
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
        let take = Take(takeURL: audioRecorder.url, date: Date(), userLocation: userLocation!, length: length)
        Takes.sharedInstance.takesLocal.append(take)
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
    
    /// Audio level screen -> extented == true starts audio level monitoring
    ///
    func audioLevelExtented(_ extented : Bool) {
        print("AudioLevelView extented \(extented)")
        
        if extented {
            audioInputDeviceMonitor = AudioInputDeviceMonitor()
            audioInputDeviceMonitor.startCaptureSession() { result in
                print(result)
                //self.audioLevelView.updateLevel(level: result)
            }
        } else {
            audioInputDeviceMonitor.stopCaptureSession()
        }
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
 
    /**
     Make a valid take name
     
     */
    private func makeTakeName() -> String {
        // test takename
        let ubiqutios =  CloudDataManager.sharedInstance.takeDirectories
        
        switch userSettings!.takeNameExtension {
        case "index":
            let nextIndex = Takes().getIndexForName(name: takeNamePreset,
                                                    seperator: "_",
                                                    type: userSettings!.takeNameExtension,
                                                    indexLength: 4,
                                                    ubiqutios: ubiqutios)
            return "\(takeNamePreset)_\(nextIndex)"
            
        case "date_index":
            let today = Date().toString(dateFormat: "dd-MM-YY")
            let presetAndDate = takeNamePreset + "-" + today
            let nextIndex = Takes().getIndexForName(name: presetAndDate, seperator: "_",
                                                    type: userSettings!.takeNameExtension,
                                                    indexLength: 4,
                                                    ubiqutios: ubiqutios)
            return "\(presetAndDate)_\(nextIndex)"
         
        case "date_time":
            let today = Date().toString(dateFormat: "dd-MM-YY'_at_'hh-mm-ss" )
            return "\(takeNamePreset)_\(today)"
            
        default:
            return takeNamePreset
        }
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
