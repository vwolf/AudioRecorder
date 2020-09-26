//
//  AudioInputVisualizer.swift
//  AudioRecorder
//
//  Created by Wolf on 02.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit
import Accelerate
import AVFoundation

class AudioInputVisualizer: UIView {
    
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet var ContentView: UIView!
    
    var barView: UIView = UIView()
    
    let noiseFloor: Float = -80
    
    var bars = [CAShapeLayer]()
    let numberOfBars = 12
    let barWidth = 12
    var activeBar = 0
    
    //
    var audioRecorder: AVAudioRecorder?
    private var levelUpdateTimer: Timer?
    
    // use when loading in code
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    // use when loading in IB
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("AudioInputVisualizer", owner: self, options: nil)
        addSubview(ContentView)
        ContentView.frame = self.bounds
        ContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        ContentView.backgroundColor = UIColor.black
        
        barView = addBarView()
        ContentView.addSubview(barView)
        
        label.isHidden = true
    }
    
    // MARK: Visualizer Display
    
    private func addBarView() -> UIView {
        let barViewSize = CGSize(width: numberOfBars * barWidth, height: 100)
        let leftOfBarView = ContentView.bounds.size.width / 2 + barViewSize.width / 2
        let barViewPosition = CGPoint(x: leftOfBarView, y: 0)
        
        barView = UIView.init(frame: CGRect(origin: barViewPosition, size: barViewSize))
        
        addBars(numberOfBars: numberOfBars)
        
        return barView
    }
    
    private func addBars(numberOfBars: Int) {
        let barTop = 50
        let barHeight = 50
        
        for index in 0...numberOfBars - 1 {
            let shape = CAShapeLayer()
            let shapePath = UIBezierPath(
            roundedRect: CGRect(x: barWidth * index, y: barTop, width: barWidth, height: barHeight),
            byRoundingCorners: [.topRight, .topLeft],
            cornerRadii: CGSize(width: 2, height: 2))
            
            shape.path = shapePath.cgPath
//            shape.strokeColor = UIColor.white.cgColor
            shape.strokeColor = Colors.Base.baseGreen.toUIColor().cgColor
            shape.fillColor = UIColor.black.cgColor
            shape.lineWidth = 1
            barView.layer.addSublayer(shape)
            
            bars.append(shape)
        }
    }
    
    func setBarViewPosition() {
        print("superView.bounds.width: \(String(describing: superview?.bounds.width))")
        print("barView.origine: \(barView.bounds.origin)")
        barView.frame.origin.x = (superview?.bounds.width)! / 2 - barView.frame.size.width / 2
    }
    
    /**
     Start visualizing input level
     */
    func startVisualize(audioRecorder: AVAudioRecorder, updateInterval: Double = 0.05) {
        self.audioRecorder = audioRecorder
        
        levelUpdateTimer = Timer.scheduledTimer(timeInterval: updateInterval,
        target: self,
        selector: #selector(self.updateLevel),
        userInfo: nil,
        repeats: true)
    }
    
    func stopVisualize() {
        guard levelUpdateTimer != nil, levelUpdateTimer!.isValid else {
            return
        }
        
        levelUpdateTimer?.invalidate()
        levelUpdateTimer = nil
    }
    
    
    @objc private func updateLevel() {
        audioRecorder?.updateMeters()
        let power = averagePowerFromAllChannels()
        //print(power)
        setLevel(level: Float(power))
        
    }
    
     func averagePowerFromAllChannels() -> CGFloat {
        var power: CGFloat = 0.0
        
        (0..<(audioRecorder?.format.channelCount)!).forEach { (index) in
            power  = power + CGFloat((audioRecorder?.averagePower(forChannel: Int(index)))!)
        }
        
        return power / CGFloat( (audioRecorder?.format.channelCount)! )
    }
    
    // MARK: Visualize Update
    
    private func setLevel(level: Float) {
        
        let normalizedLevel = normalizeSoundLevel(level: level)
        
        let barShapePath = UIBezierPath(
            roundedRect: CGRect(x: CGFloat(activeBar) * CGFloat(barWidth), y: 100 - normalizedLevel, width: CGFloat(barWidth), height: normalizedLevel), byRoundingCorners: [.topRight, .topLeft], cornerRadii: CGSize(width: 2, height: 2))
        
        bars[activeBar].path = barShapePath.cgPath
        if activeBar == numberOfBars - 1 {
            activeBar = 0
        } else {
            activeBar += 1
        }
    }
    
    
    private func normalizeSoundLevel(level: Float) -> CGFloat {
           let level = max(0.2, CGFloat(level) + 50) / 2
           
           return CGFloat(level * (100 / 25))
       }
}
