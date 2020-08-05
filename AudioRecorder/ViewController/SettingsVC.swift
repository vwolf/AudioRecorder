//
//  SettingsVC.swift
//  AudioRecorder
//
//  Created by Wolf on 04.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class SettingsVC: UIViewController {

    //var tableData = [String]()
    // settings format: [[String, String], [],], idx 0 is name, 1 is value
    var tableData = [[["Name", "Default"], ["SampleRate", "44.100"]], [["RecordingSettings", "High"]]]
    var tableHeaders = ["Recording Settings", "User Settings"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50))
        let label = UILabel()
        
        label.frame = CGRect(x: 5, y: 5, width: headerView.frame.width - 10, height: headerView.frame.height - 10)
        label.text = tableHeaders[section]
        
        // label.font
        label.textColor = Colors.Base.background.toUIColor()
        
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
        
        cell.nameLabel.text = tableData[indexPath.section][indexPath.row][0]
        cell.valueLabel.text = tableData[indexPath.section][indexPath.row][1]
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("SettingsVC.selectRowAt: \(indexPath.row)")
        
        print("Settings name: \(tableData[indexPath.section][indexPath.row][0])")
        
    }
    

}
