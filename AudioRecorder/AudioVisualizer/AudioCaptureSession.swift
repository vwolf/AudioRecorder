//
//  AudioCaptureSession.swift
//  AudioRecorder
//
//  Created by Wolf on 03.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import AVFoundation

/**
 Use to record audio
 */
class AudioCaptureSession: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    let captureSession = AVCaptureSession()
    
    
    override init() {
        super.init()
        
        let queue = DispatchQueue(label: "AudioSessionQueue", attributes: [])
        //let captureDevice = AVCaptureDevice.default(for: .audio)
        let captureDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)
        
        var audioInput: AVCaptureDeviceInput? = nil
        var audioOutput: AVCaptureAudioDataOutput? = nil
        
        do {
            try captureDevice?.lockForConfiguration()
            audioInput = try AVCaptureDeviceInput(device: captureDevice!)
            captureDevice?.unlockForConfiguration()
            
            audioOutput = AVCaptureAudioDataOutput()
            audioOutput?.setSampleBufferDelegate(self, queue: queue)
        } catch {
            print(error.localizedDescription)
        }
        
        if audioInput != nil && audioOutput != nil {
            captureSession.beginConfiguration()
            
            if (captureSession.canAddInput(audioInput!)) {
                captureSession.addInput(audioInput!)
            } else {
                print("Can't add audioInput to captureSession")
            }
            
            if (captureSession.canAddOutput(audioOutput!)) {
                captureSession.addOutput(audioOutput!)
            } else {
                print("Can't add audioOutput to captureSession")
            }
            
            captureSession.commitConfiguration()
            
            print("Starting captureSession")
            captureSession.startRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Audio data received")
    }
}


class AudioInputDeviceMonitor: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    let recordingSession = AVAudioSession.sharedInstance()
    var captureSession: AVCaptureSession = AVCaptureSession()
    //var onChange:((_: Bool) -> Void)?
    var completion: ((_: Float) -> Void)?

    override init() {
        super.init()
        
        if recordingSession.isInputAvailable {
            do {
                if recordingSession.availableCategories.contains(.playAndRecord) {
                    try recordingSession.setCategory(AVAudioSession.Category.playAndRecord)
                }
                
                try recordingSession.setActive(true)
                print("InputGain in AudioInputDeviceMonitor: \(recordingSession.inputGain)")
                try recordingSession.setInputGain(1.0)
                
            } catch {
            
            }
            
        }
    }
    
    func startCaptureSession(closure: @escaping (Float) -> Void) {
        completion = closure
        
        if let audioCaptureDevice: AVCaptureDevice = AVCaptureDevice.default(for: AVMediaType.audio) {
            do {
                try audioCaptureDevice.lockForConfiguration()
                
               
                let audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
                audioCaptureDevice.unlockForConfiguration()
                
                if (captureSession.canAddInput(audioInput)) {
                    captureSession.addInput(audioInput)
                }
                
                let audioOutput = AVCaptureAudioDataOutput()
                
                audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .default))
                if (captureSession.canAddOutput(audioOutput)) {
                    captureSession.addOutput(audioOutput)
                }
                
                DispatchQueue.global(qos: .default).async {
                    print("start captureSession")
                    self.captureSession.startRunning()
                }
            } catch {
                
            }
        }
    }
    
    /// Delegate function captureSession result
    ///
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let audioChannel = connection.audioChannels.first {
//            print("averagePowerLevel: \(audioChannel.averagePowerLevel)")
//            print("peakHoldLevel: \(audioChannel.peakHoldLevel)")
            completion!(audioChannel.averagePowerLevel)
        }
    }
    
    
    func stopCaptureSession() {
        captureSession.stopRunning()
    }
}
