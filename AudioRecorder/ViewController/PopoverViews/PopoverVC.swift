//
//  PopoverVC.swift
//  AudioRecorder
//
//  Created by Wolf on 26.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

class PopoverVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    //var tableData = [String]()
    var tableData = ["Car", "Bike", "Bus", "Van", "Bicycle"]
    var instruction: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib.init(nibName: "PopoverCell", bundle: nil), forCellReuseIdentifier: "PopoverCellIdentifier")
        
        instructionLabel.text = instruction
    }
}


extension PopoverVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PopoverCellIdentifier", for: indexPath) as! PopoverCellController
        
        cell.valueLabel.text = tableData[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
