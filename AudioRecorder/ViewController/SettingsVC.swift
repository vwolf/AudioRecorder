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

/**
 ViewController for Settings screen.
 Settings screen has two parts: Audio format and User settings
 
 */
class SettingsVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    // settings format: [[String, String], [],], idx 0 is name, 1 is value
    //var tableData = [[["Name", "Default"], ["SampleRate", "44.100"]], [["RecordingSettings", "High"]]]
    var tableHeaders = ["Recording Settings", "User Settings"]
    var takeNamePreset = "myRecording + timestamp"
    var displaySetting = [[Setting]]()
    
    var settings: Settings?
    var userSettings: UserSettings?
    
    // comming from ShareVC
    var parentIsShareVC = false
    var callingShareVC: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if settings == nil {
            
        }
        //displaySetting = (settings?.settingForDisplay(name: settings!.currentSettingsName))!
    }
    
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        
        // when moving back, parent parameter is nil
        if (parent == nil) {
            if parentIsShareVC == true {
                print("willMove")
                var viewControllers = navigationController?.viewControllers
                print("viewControllers.count: \(viewControllers!.count)")
                let vcCount = viewControllers!.count
                if vcCount > 2 {
                    let classForCoderName = NSStringFromClass(viewControllers![vcCount - 2].classForCoder).components(separatedBy: ".").last
                    print(classForCoderName!)
                    
                    switch userSettings?.shareClient {
                    case "iCloud":
                        // if viewController to go to is not ShareVC then replace
                        if classForCoderName! != "ShareVC" {
                            
                        }
                    case "Dropbox":
                        if classForCoderName! != "DropboxVC" {
                            let dbVC = DropboxVC()
                            viewControllers?.replaceSubrange(vcCount - 2..<vcCount - 1, with: [dbVC])
                            //viewControllers?.insert(dbVC, at: vcCount - 2)
                            navigationController?.setViewControllers(viewControllers!, animated: false)
                        }
                        
                    default:
                        print("Unknown shareClient")
                    }
                }
            }
        }
    }
    
    /**
     Update takename preset 
     */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let viewControllers = self.navigationController?.viewControllers {
            if (viewControllers.count >= 1) {
                let previousViewController = viewControllers[viewControllers.count - 1] as! RecordVC
                previousViewController.takeNamePreset = userSettings!.takeName
            }
        }
    }
    
    /**
     Settings value changed
     Usersetting->Name of Recording Setting then update Format Settings
     
     - parameter indexPath: tableView indexPath of change setting
     - parameter value: new value
     */
    private func settingValueUpdate(indexPath: IndexPath, value: String) {
        switch displaySetting[indexPath.section][indexPath.row].id {
        case "recordingSettings" :
            self.displaySetting[indexPath.section][indexPath.row].value = value
            self.tableView.reloadRows(at: [indexPath], with: .fade)
            // changed recording setting name, load new setting
            _ = settings?.getSetting(name: value)
            let displaySettingData = settings!.settingForDisplay(name: settings?.currentSettingsName ?? "Default")
            displaySetting[0] = displaySettingData
            tableView.reloadData()
            
            userSettings?.updateUserSetting(name: "recordingSettings", value: value)
         
        case "style":
            self.displaySetting[indexPath.section][indexPath.row].value = value
            userSettings?.updateUserSetting(name: "style", value: value)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
            
        case "takename":
            self.displaySetting[indexPath.section][indexPath.row].value = value
            userSettings?.updateUserSetting(name: "takename", value: value)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        
        case "shareClient":
            self.displaySetting[indexPath.section][indexPath.row].value = value
            userSettings?.updateUserSetting(name: "shareClient", value: value)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
            
        default:
            print("nothing to update")
        }
    }
//    private func settingsToList() -> [[String]] {
//        let currentSetting = settings?.getCurrentSetting()
//        var settingsName = "Default"
//
//        if settings?.currentSettingsName != nil  {
//            settingsName = (settings?.currentSettingsName)!
//        }
//
//        let settingsList = [
//            ["Name", settingsName],
//            ["SampleRate", String(format: "%.3f", currentSetting?[AVSampleRateKey] as! CVarArg)],
//            ["Bitdepths", "\(currentSetting?[AVLinearPCMBitDepthKey] as! CVarArg)" ],
//            ["Channels", "\(currentSetting?[AVNumberOfChannelsKey] as! CVarArg)" ],
//            ["Format", "\(currentSetting?[AVFormatIDKey] as! CVarArg)" ],
//            ["Takename", "\(userSettings?.takeName)"]
//        ]
//
//        return settingsList
//    }


}

extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displaySetting[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return displaySetting.count
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
       
        let set = displaySetting[indexPath.section][indexPath.row]
        
        cell.nameLabel.text = set.name
        cell.valueLabel.text = set.value
//        if set.format == SettingDefinitions.SettingFormat.preset {
//            cell.backgroundColor = Colors.Base.baseGreen.toUIColor()
//        }
//        cell.nameLabel.text = settingData[indexPath.section][indexPath.row][0]
//        cell.valueLabel.text = settingData[indexPath.section][indexPath.row][1]
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("SettingsVC.selectRowAt: \(indexPath.row)")
        
        //print("Settings name: \(settingData[indexPath.section][indexPath.row][0])")
        
        if displaySetting[indexPath.section][indexPath.row].format == SettingDefinitions.SettingFormat.preset {
            switch displaySetting[indexPath.section][indexPath.row].id {
            case "recordingSettings" :
                // get all awailable recording format preset names
                let names = settings?.getSettingsName()
                editValue(index: indexPath, values: names!)
                
            case "style" :
                let styles = ["dark", "light"]
                editValue(index: indexPath, values: styles)
             
            case "shareClient":
                editValue(index: indexPath, values: ["iCloud", "Dropbox"])
                
            default:
                print("nothing to edit")
            }
            //editValue()
        }
        
        if displaySetting[indexPath.section][indexPath.row].format == SettingDefinitions.SettingFormat.userDefined {
            switch displaySetting[indexPath.section][indexPath.row].id {
            case "takename" :
                newValue(indexPath: indexPath, currentValue: displaySetting[indexPath.section][indexPath.row].value)
            default:
                print("nothing to edit")
            }
        }
        // setting name:
    }
    

    /**
     User can edit settings values
     
     - parameter index: selected tableView cell
     - parameter values: Values to display in alert
     */
    func editValue(index: IndexPath, values: [String]) {
        
//        let popoverContentController = PopoverVC(nibName: "PopoverTableView", bundle: nil)
//        let section = tableHeaders[index.section]
        
        // user defined value -> show alert with textField to edit value
        let alert = UIAlertController(title: "Select", message: nil, preferredStyle: .alert)
        
        let closure = { (action: UIAlertAction!) -> Void in
            let indexSelected = alert.actions.firstIndex(where: { $0 === action})
            if (indexSelected != nil) {
                print("selected: \(values[indexSelected!])")
                self.settingValueUpdate(indexPath: index, value: values[indexSelected!])
            }
        }
        
        
        for item in values {
            alert.addAction(UIAlertAction(title: item, style: .default, handler: closure))
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            
        }
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /**
     User can enter a new value for selected setting
     
     - parameter indexPath: selected tableView cell
     - parameter currentValue: currently value of cell at indexPath
     */
    func newValue(indexPath: IndexPath, currentValue: String) {
        
        let alert = UIAlertController(title: "Enter Name Base", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = currentValue
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            let textField = alert.textFields![0] as UITextField
            print("Text in textField: \(String(describing: textField.text))")
            self.settingValueUpdate(indexPath: indexPath, value: textField.text!)
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
        
    }
}
