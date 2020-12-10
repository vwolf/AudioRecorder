//
//  AudioInputLevelView.swift
//  AudioRecorder
//
//  Created by Wolf on 07.12.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit
import Foundation

class AudioInputLevelView: UIView {

    @IBOutlet var ContentView: UIView!
    @IBOutlet weak var levelView: UIView!
    
    // this view cover the levelView to simulate changing levels
    var levelCoverView: UIView!
    
    var newLevel: CGFloat = 50
    var completion: ((_ extented : Bool) -> Void)?
    var audioInputDeviceMonitor: AudioInputDeviceMonitor!
    var dbDisplayFactor: CGFloat = 1.0
    
    var visible = false
    
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
        
        Bundle.main.loadNibNamed("AudioInputLevelView", owner: self, options: nil)
        self.frame.size = ContentView.frame.size
        addSubview(ContentView)
        ContentView.frame = self.bounds
        ContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        ContentView.backgroundColor = Colors.Base.background.toUIColor()
        
        /// Gradient for level view
        let colorTop = UIColor.red.cgColor
        let colorMiddle = UIColor.orange.cgColor
        let colorBottom = UIColor.green.cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorMiddle, colorBottom]
        gradientLayer.locations = [0.0, 0.2, 1.0]
        gradientLayer.frame = levelView.bounds
        levelView.layer.insertSublayer(gradientLayer, at:0)
        
        let levelCoverViewSize = levelView.bounds.size
        levelCoverView = UIView.init(frame: CGRect(origin: levelView.frame.origin, size: levelCoverViewSize))
        levelCoverView.backgroundColor = Colors.Base.background_item_light.toUIColor()
        addSubview(levelCoverView)
        
        dbDisplayFactor = levelView.frame.height / 100
        
        //setVisible(state: false)
    }
    
    func onMove() {
        if !visible {
//            let visibleFrame = CGRect(x: (superview?.frame.maxX)! - frame.width, y: frame.origin.y, width: frame.width, height: frame.height)
//            UIView.animate(withDuration: 0.5, animations: {
//                self.frame = visibleFrame
//            })
            isHidden = false
            startCaptureSession()
        } else {
//            let inVisibleFrame = CGRect(x: (superview?.frame.maxX)!, y: frame.origin.y, width: frame.width, height: frame.height)
//            UIView.animate(withDuration: 0.5, animations: {
//                self.frame = inVisibleFrame
//            })
            isHidden = true
            stopCaptureSession()
        }
        visible = !visible
    }
    
    func setVisible(state: Bool) {
        if state {
            
        } else {
            let inVisibleFrame = CGRect(x: (superview?.frame.maxX)!, y: frame.origin.y, width: frame.width, height: frame.height)
            self.frame = inVisibleFrame
        }
    }
    /// Start audio input capture session.
    /// AVCaptureSession runs async on main queue. Direct update of view is not possible. Start a timer to update to new level values.
    ///
    func startCaptureSession() {
        audioInputDeviceMonitor = AudioInputDeviceMonitor()
        audioInputDeviceMonitor.startCaptureSession() { result in
            let linearLevel = powf(10, result / 20)
            //print("linearLevel: \(linearLevel)")
            let levelToDisplay = (1 - linearLevel) * 100
            self.newLevel = CGFloat(levelToDisplay) * self.dbDisplayFactor
            //print("level: \(self.newLevel)")
        }
        startUpdateLevel()
    }
    
    
    func stopCaptureSession() {
        if (audioInputDeviceMonitor != nil) {
            audioInputDeviceMonitor.stopCaptureSession()
        }
        stopUpdateLevel()
    }
    
    
    weak var timer: Timer?
  
    func startUpdateLevel() {
        timer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(updateLevel),
            userInfo: nil,
            repeats: true)
    }
    
    @objc func updateLevel() {
        // random value 0..50
        //let newHeight = Int.random(in: 1..<100)
        levelCoverView.frame.size.height = newLevel
    }
    
    func stopUpdateLevel() {
        timer?.invalidate()
    }
    
}
