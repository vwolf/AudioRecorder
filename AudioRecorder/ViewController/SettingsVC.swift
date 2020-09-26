//
//  SettingsVC.swift
//  Settings as two sections: Recording Settings and User Settings
//
//  AudioRecorder
//
//  Created by Wolf on 04.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit
import AVFoundation

class SettingsVC: UIViewController {
    
    //var tableData = [String]()
    // settings format: [[String, String], [],], idx 0 is name, 1 is value
    var tableData = [[["Name", "Default"], ["SampleRate", "44.100"]], [["RecordingSettings", "High"]]]
    var tableHeaders = ["Recording Settings", "User Settings"]
    
    var takeNamePreset = "myRecording + timestamp"
    
    var settingData = [[[String]]]()
    var settings: Settings?
    var userSettings: UserSettings?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    private func settingsToList() -> [[String]] {
        let currentSetting = settings?.getCurrentSetting()
        var settingsName = "Default"
        
        if settings?.currentSetting != nil  {
            settingsName = (settings?.currentSetting)!
        }
        
        let settingsList = [
            ["Name", settingsName],
            ["SampleRate", String(format: "%.3f", currentSetting?[AVSampleRateKey] as! CVarArg)],
            ["Bitdepths", "\(currentSetting?[AVLinearPCMBitDepthKey] as! CVarArg)" ],
            ["Channels", "\(currentSetting?[AVNumberOfChannelsKey] as! CVarArg)" ],
            ["Format", "\(currentSetting?[AVFormatIDKey] as! CVarArg)" ],
            ["Takename", "\(userSettings?.takeName)"]
        ]
        
        return settingsList
    }


}

extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingData[section].count
//        return tableData[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingData.count
//        return tableData.count
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50))
        let label = UILabel()
        
        label.frame = CGRect(x: 5, y: 5, width: headerView.frame.width - 10, height: headerView.frame.height - 10)
        label.text = tableHeaders[section]
        
        // label.font
        label.textColor = Colors.Base.text_01.toUIColor()
        
        headerView.backgroundColor = Colors.Base.background.toUIColor()
        headerView.addSubview(label)
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableViewCellIdentifier", for: indexPath) as? SettingsTableViewCell else {
            fatalError("The dequeued cell is not an instance of SettingTableViewCell")
        }
       
        cell.nameLabel.text = settingData[indexPath.section][indexPath.row][0]
        cell.valueLabel.text = settingData[indexPath.section][indexPath.row][1]
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("SettingsVC.selectRowAt: \(indexPath.row)")
        
        print("Settings name: \(settingData[indexPath.section][indexPath.row][0])")
        
        editValue(index: indexPath)
        // setting name:
    }
    

    /**
     User can edit settings values
     
     - parameter index: selected tableView cell
     */
    func editValue(index: IndexPath) {
        
        let popoverContentController = PopoverVC(nibName: "PopoverTableView", bundle: nil)
        let section = tableHeaders[index.section]
        
        // what to edit
        popoverContentController.instruction = section + ":" + settingData[index.section][index.row][0]
        // preset values -> show tableView to select value
        self.present(popoverContentController, animated: true)
        
        // user defined value -> show alert with textField to edit value
        
    }
}
