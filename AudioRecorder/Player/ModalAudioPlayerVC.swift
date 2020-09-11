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
    
    var audioPlayer: AVAudioPlayer?
    var takeURL: URL?
    var takePath: String?
    
    var takeName = "" {
        didSet {
            takeNameLabel.text = takeName
         
            rewindBtn.isEnabled = false
            forwardBtn.isEnabled = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        takeNameLabel.textColor = Colors.AVModal.textColor.toUIColor()
    }
    
    
    @IBAction func playAudio(_ sender: UIBarButtonItem) {
        guard let currentURL = Takes().getUrlforFile(fileName: takeName) else {
            NSLog("Error playing \(takeName): No URL for takeName")
            return
        }
        takeURL = currentURL
        
        // no audioPlayer - create AVAudioPlayer then start audio
        if audioPlayer == nil {
            if playSound() {
                tooglePlayBtn(state: "pause")
//                let newPauseBtn = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(ModalAudioPlayerVC.pauseAudio(_:)))
//                toolbar.items?[2] = newPauseBtn
            }
        } else {
            // replay audio
            audioPlayer?.play()
            if audioPlayer!.isPlaying {
                tooglePlayBtn(state: "pause")
//                let newPauseBtn = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(ModalAudioPlayerVC.pauseAudio(_:)))
//                toolbar.items?[2] = newPauseBtn
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
//                let newPlayBtn = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(ModalAudioPlayerVC.playAudio(_:)))
//                toolbar.items?[2] = newPlayBtn
            }
        }
    }
    
    func playSound() -> Bool {
        //let url = takeURL
        
        guard let currentURL = Takes().getUrlforFile(fileName: takeName) else {
            NSLog("Error playing \(takeName): No URL for takeName")
            return false
        }
        print("playSound: \(currentURL)")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: currentURL)
            audioPlayer?.delegate = self
            
            let prepare = audioPlayer?.prepareToPlay()
            print("prepare result: \(String(describing: prepare))")
            
            audioPlayer?.play()
            
            print("player is playing: \(String(describing: audioPlayer?.isPlaying))")
            return true
        } catch {
            
        }
        
        return false
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("audioPlayerDidFinishPlaying: \(flag)")
        //onTakeFinished(flag: flag)
        tooglePlayBtn(state: "play")
        
        audioPlayer?.stop()
        audioPlayer = nil
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
}
