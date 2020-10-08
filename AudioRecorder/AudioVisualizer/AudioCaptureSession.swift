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
