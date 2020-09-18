//
//  MetadataAddPopoverVC.swift
//  AudioRecorder
//
//  Created by Wolf on 18.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class MetadataAddPopoverVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    let tableData = ["Image", "Audio"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        instructionLabel.text = MetaDataStrings().addMetadataInstruction
        tableView.register(UINib.init(nibName: "MetadataAddCell", bundle: nil), forCellReuseIdentifier: "MetadataAddCellIdentifier")
    }

}

extension MetadataAddPopoverVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MetadataAddCellIdentifier", for: indexPath) as! MetadataAddCellController
        cell.nameLabel.text = tableData[indexPath.row]
//        cell.textLabel?.text = tableData[indexPath.row]
        return cell
    }
    
    
}
