//
//  GainView.swift
//  AudioRecorder
//
//  Created by Wolf on 06.12.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

class AudioInputGainView: UIView {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var gainLabel: UILabel!
    @IBOutlet weak var gainValueLabel: UILabel!
    @IBOutlet weak var gainSlider: UISlider!
    
    var visible = false
    var gain: Float = 0.00 {
        didSet {
            gainValueLabel.text = String(format: "%2f", gain)
            recorder?.setInputGain(gain: gain)
        }
    }
    
    var recorder: Recorder?
    
    // use when loading in code
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    
    // use when loading in IB
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //self.translatesAutoresizingMaskIntoConstraints = false
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("AudioInputGainView", owner: self, options: nil)
        self.frame.size = contentView.frame.size
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.backgroundColor = Colors.Base.background.toUIColor()

    }
    
    
    @IBAction func gainSliderChange(_ sender: UISlider) {
//        print("slider changed: \(sender.value)")
        gain = sender.value
//        gainValueLabel.text = String(format: "%.2f", sender.value)
//        gainValueLabel.text = "0.0"
    }
    
    func onMove() {
        let curFrame = self.frame
        if !visible {
            let newFrame = CGRect(x: 30, y: curFrame.origin.y, width: curFrame.width, height: self.frame.height)
            UIView.animate(withDuration: 1.0, animations: {
                self.frame = newFrame
            })
//            startCaptureSession()
        } else {
            let newFrame = CGRect(x: -curFrame.width, y: curFrame.origin.y, width: self.frame.width, height: self.frame.height)
            UIView.animate(withDuration: 0.5, animations: {
                self.frame = newFrame
            })
//            stopCaptureSession()
        }
        visible = !visible
//        //completion!(extented)
    }
    
}
