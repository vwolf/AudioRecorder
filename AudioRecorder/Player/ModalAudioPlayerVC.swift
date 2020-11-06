//
//  ModalAudioPlayerViewController.swift
//  AudioRecorder
//
//  Created by Wolf on 01.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class ModalAudioPlayerVC: UIViewController, AVAudioPlayerDelegate {
    
    
    @IBOutlet weak var takeNameLabel: UILabel!
    @IBOutlet weak var toolbar: UIToolbar!
    
    @IBOutlet weak var playBtn: UIBarButtonItem!
    @IBOutlet weak var rewindBtn: UIBarButtonItem!
    @IBOutlet weak var forwardBtn: UIBarButtonItem!
    
    @IBOutlet weak var middleWaveformView: WaveformImageView!
    @IBOutlet weak var currentPositionLine: UIView!
    
    var audioPlayer: AVAudioPlayer?
    var takeURL: URL?
    var takePath: String?
    
//    @IBAction func positionLineGesture(_ sender: UITapGestureRecognizer) {
//        print("positionLineGesture")
//    }
    
       
    var takeName = "" {
        didSet {
            takeNameLabel.text = takeName
         
            rewindBtn.isEnabled = false
            forwardBtn.isEnabled = false
        }
    }
    
    // AudioPlayer time and timeline marker
    var panGesture = UIPanGestureRecognizer()
    var timer: Timer?
    var positionLineStep: CGFloat = 0.0
    
    var lengthProPercent: CGFloat = 0.0
    // current position of marker line (x axis)
    var positionLinePos: CGFloat = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        takeNameLabel.textColor = Colors.AVModal.textColor.toUIColor()
        
        // setup dragging of position line, scrubbing timeline
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.dragPositionLine))
        currentPositionLine.isUserInteractionEnabled = true
        currentPositionLine.addGestureRecognizer(panGesture)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //let waveformImageDrawer = WaveformImageDrawer()
        if takeURL == nil {
            takeURL = Takes().getUrlforFile(fileName: takeName)
        }
        
        middleWaveformView.waveformColor = UIColor.red
        middleWaveformView.waveformAudioURL = takeURL
        
        currentPositionLine.frame.origin = middleWaveformView.frame.origin
        currentPositionLine.frame.size.height = middleWaveformView.frame.size.height
        
        //waveformImageDrawer.waveformImage(fromAudioAt: audioURL, size: <#T##CGSize#>, completionHandler: <#T##(UIImage?) -> ()#>)
    }
    
    
    @IBAction func playAudio(_ sender: UIBarButtonItem) {
        if takeURL == nil {
            guard let currentURL = Takes().getUrlforFile(fileName: takeName) else {
                NSLog("Error playing \(takeName): No URL for takeName")
                return
            }
            takeURL = currentURL
        }
        
        // no audioPlayer - create AVAudioPlayer then start audio
        if audioPlayer == nil {
            if playSound() {
                tooglePlayBtn(state: "pause")
            }
        } else {
            // replay audio or play at position of marker line
            if resumePlay() {
                tooglePlayBtn(state: "pause")
            }
        }
    }
    
    @IBAction func rewindAudio(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func forwardAudio(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func pauseAudio(_ sender: Any) {
        if audioPlayer != nil {
            if (audioPlayer?.isPlaying)! {
                audioPlayer?.pause()
                tooglePlayBtn(state: "play")
                stopTimer()
            }
        }
    }
    
    func playSound() -> Bool {
        //let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
//        guard let currentURL = Takes().getUrlforFile(fileName: takeName) else {
//            NSLog("Error playing \(takeName): No URL for takeName")
//            return false
//        }
//        print("playSound: \(currentURL)")
        let currentURL = takeURL
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: currentURL!)
            audioPlayer?.delegate = self
            print("take with duration: \(audioPlayer?.duration)")
            if audioPlayer?.duration == 0.0 { return false }
            let prepare = audioPlayer?.prepareToPlay()
            print("prepare result: \(String(describing: prepare))")
            //print("take with duration: \(audioPlayer?.duration)")
            positionLineStep = (middleWaveformView.bounds.size.width / CGFloat(audioPlayer!.duration))
            
            // use for scrubbing timeline
            lengthProPercent = middleWaveformView.bounds.size.width / 100
            // current time of audioPlayer
            let timeToStart = (positionLinePos / lengthProPercent) *  (CGFloat(audioPlayer!.duration) / 100)
            
            audioPlayer?.currentTime = Double(timeToStart)
            audioPlayer?.play()
            startTimer()
            
            print("player is playing: \(String(describing: audioPlayer?.isPlaying))")
            return true
        } catch {
            
        }
        
        return false
    }
    
    func resumePlay() -> Bool {
        let timeToResume = (positionLinePos / lengthProPercent) * (CGFloat(audioPlayer!.duration) / 100)
        audioPlayer?.currentTime = Double(timeToResume)
        audioPlayer?.play()
        startTimer()
        return true
    }
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("audioPlayerDidFinishPlaying: \(flag)")
        //onTakeFinished(flag: flag)
        tooglePlayBtn(state: "play")
        
        audioPlayer?.stop()
        stopTimer()
        audioPlayer = nil
        
        movePositionView(to: "start")
    }
    
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Error \(String(describing: error))")
    }
    
    
    private func tooglePlayBtn(state: String) {
        if state == "pause" {
            let newBtn = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(ModalAudioPlayerVC.pauseAudio(_:)))
            toolbar.items?[2] = newBtn
        }
        
        if state == "play" {
            let newBtn = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(ModalAudioPlayerVC.playAudio(_:)))
            toolbar.items?[2] = newBtn
        }
       
    }
    
    
    private func startTimer() {
        
        timer = Timer.scheduledTimer(timeInterval: 0.01,
                                     target: self,
                                     selector: #selector(updateCurrentTime),
                                     userInfo: nil,
                                     repeats: true)
        
    }
    
    private func stopTimer() {
        //print(audioPlayer?.duration)
        //print(audioPlayer?.currentTime)
        timer?.invalidate()
        //movePositionView(to: "custom")
    }
    
    
    @objc func updateCurrentTime() {
       // print(audioPlayer?.currentTime)
        movePositionView(to: "custom")
    }
    
    private func movePositionView(to position: String?) {
        //let stepPerSecond = middleWaveformView.bounds.size.width / CGFloat(audioPlayer!.duration)
        var currentPosition: CGFloat = 0.0
        switch position {
        case "custom":
            currentPosition = positionLineStep * CGFloat(audioPlayer!.currentTime)
            
        case "start":
            currentPosition = middleWaveformView.frame.origin.x
            
        case "end":
            currentPosition = middleWaveformView.frame.maxX
            
        default:
            print("position \(String(describing: position))?")
        }
        currentPositionLine.frame.origin.x = currentPosition
        positionLinePos = currentPosition
    }
    
    
    @objc func dragPositionLine(_ sender: UIPanGestureRecognizer) {
        //print("sender.state: \(sender.state.rawValue)")
        if sender.state == UIPanGestureRecognizer.State.ended {
            print("ENDED at \(currentPositionLine.frame.midX)")
    
            currentPositionLine.center.x = max(0, (min(middleWaveformView.frame.size.width, currentPositionLine.frame.midX )))
            print(currentPositionLine.center.x)
            
            positionLinePos = currentPositionLine.center.x
            
        } else {
            self.view.bringSubviewToFront(currentPositionLine)
            let translation = sender.translation(in: self.view)
            //print(translation.x)
            currentPositionLine.center = CGPoint(x: currentPositionLine.center.x + translation.x, y: currentPositionLine.center.y)
        }
        
        sender.setTranslation(CGPoint.zero, in: self.view)
        
    }
}
