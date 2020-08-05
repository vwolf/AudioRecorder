//
//  RecordingTimer.swift
//  AudioRecorder
//
//  Created by Wolf on 04.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

/**
Timer and Label to display time value
*/
class RecordingTimer: UILabel {
    weak var timer: Timer?
    var timerValue = 0.0
    
    
    func startTimer() {
        timerValue = 0.0
        timer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(updateTime),
            userInfo: nil,
            repeats: true)
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    func resetTimer() {
        timerValue = 0
        self.text = timeString(time: timerValue)
    }
    
    
    
    @objc func updateTime() {
        timerValue += 1.0
        self.text = timeString(time: timerValue)
    }
    
    private func timeString(time: Double) -> String {
        let seconds = time / 10
        return String("\(seconds) sec")
    }
}
