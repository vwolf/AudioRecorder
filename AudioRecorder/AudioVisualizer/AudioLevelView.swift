//
//  AudioLevelView.swift
//  AudioRecorder
//
//  Created by Wolf on 02.12.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

/// View to display audio level.
/// If view is extented, then activate a AudioCaptureSession
///
///
class AudioLevelView: UIView {
    
    var extented = false
    var frameOffset: CGFloat = 60
    
    var levelView: UIView!
    var levelCoverView: UIView!
    
    var newLevel: CGFloat = 50
    
    var completion: ((_ extented : Bool) -> Void)?
    
    var audioInputDeviceMonitor: AudioInputDeviceMonitor!
    
    var dbDisplayFactor: CGFloat = 1.0
    
    // use when loading in code
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    
    // use when loading in IB
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = Colors.Base.background.toUIColor()
        
        self.layer.cornerRadius = 4
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.lightGray.cgColor
        
        // level view
        let levelViewSize = CGSize(width: 20, height: self.frame.height)
       // let leftOfBarView = self.bounds.size.width / 2 + barViewSize.width / 2
        let levelViewPosition = CGPoint(x: 4, y: 0)
        
        levelView = UIView.init(frame: CGRect(origin: levelViewPosition, size: levelViewSize))
        levelView.backgroundColor = UIColor.green
        addSubview(levelView)
        
        let colorTop = UIColor.red.cgColor
        let colorMiddle = UIColor.orange.cgColor
        let colorBottom = UIColor.green.cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorMiddle, colorBottom]
        gradientLayer.locations = [0.0, 0.2, 1.0]
        gradientLayer.frame = levelView.bounds
        levelView.layer.insertSublayer(gradientLayer, at:0)
        
        let levelCoverViewSize = CGSize(width: 20, height: frame.size.height)
        levelCoverView = UIView.init(frame: CGRect(origin: levelViewPosition, size: levelCoverViewSize))
        levelCoverView.backgroundColor = Colors.Base.background.toUIColor()
        addSubview(levelCoverView)
        
        dbDisplayFactor = frame.height / 100
        print("dbDisplayFactor: \(dbDisplayFactor)")
//        let colorTop =  UIColor(red: 255.0/255.0, green: 149.0/255.0, blue: 0.0/255.0, alpha: 1.0).cgColor
//        let colorBottom = UIColor(red: 255.0/255.0, green: 94.0/255.0, blue: 58.0/255.0, alpha: 1.0).cgColor
          
        
    }
    
    
    func onMove() {
        let curFrame = self.frame
        if !extented {
            let newFrame = CGRect(x: curFrame.origin.x - frameOffset, y: curFrame.origin.y, width: curFrame.width, height: self.frame.height)
            UIView.animate(withDuration: 1.0, animations: {
                self.frame = newFrame
            })
            startCaptureSession()
        } else {
            let newFrame = CGRect(x: curFrame.origin.x + frameOffset, y: curFrame.origin.y, width: self.frame.width, height: self.frame.height)
            UIView.animate(withDuration: 0.5, animations: {
                self.frame = newFrame
            })
            stopCaptureSession()
        }
        extented = !extented
        //completion!(extented)
    }
    
    /// Start audio input capture session.
    /// AVCaptureSession runs async on main queue. Direct update of view is not possible. Start a timer to update to new level values.
    ///
    func startCaptureSession() {
        audioInputDeviceMonitor = AudioInputDeviceMonitor()
        audioInputDeviceMonitor.startCaptureSession() { result in
            let linearLevel = powf(10, result / 20)
            print("linearLevel: \(linearLevel)")
            var levelToDisplay = (1 - linearLevel) * 100
            self.newLevel = CGFloat(levelToDisplay) * self.dbDisplayFactor
            print("level: \(self.newLevel)")
        }
        startUpdateLevel()
    }
    
    
    func stopCaptureSession() {
        audioInputDeviceMonitor.stopCaptureSession()
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
